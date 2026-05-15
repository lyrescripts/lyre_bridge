---@meta

---Side on which a provider is registered and resolved.
---@alias BridgeSide "client" | "server" | "shared"

---Severity passed to `bridge.core.log`.
---@alias BridgeLogType "info" | "warning" | "error" | "debug"

---Framework-specific notification color/style. Most bridges accept the
---four canonical values plus any string the underlying script supports.
---@alias BridgeNotificationType "info" | "success" | "error" | "warning" | string

---Money account name as understood by the active framework.
---@alias BridgeAccount "money" | "bank" | "black_money" | string

---Base class for any provider table created by `LyreBridge.registerProvider`.
---@class Provider
---@field __side BridgeSide
---@field __module string
---@field __name string
---@field __priority integer Lower wins; defaults to 100.
---@field __active boolean? Set to true after the first successful resolution.
---@field detect fun(self: Provider): boolean Return true to claim ownership of the module.
---@field init? fun(self: Provider) Runs once before the provider serves its first call.

---Engine-level namespace. Stores raw provider registrations, default config
---and the custom-function registry. Never exposed to consumers directly.
---@class LyreBridge
---@field providers table<BridgeSide, table<string, Provider[]>>
---@field config table<string, any> Global defaults applied to every resource configuration.
---@field debug boolean? When true, `bridge.core.log("debug", ...)` lines are printed.
---@field customFunctions table<string, table<string, function>> Keyed by `resourceName -> fnName`.

---Server-side wrapper around a framework player object. Methods on this
---table are closures captured by the active players provider; they execute
---inside `lyre_bridge`'s runtime when called from a consumer.
---@class BridgePlayer
---@field source integer Player server id.
---@field raw any Native framework player object (xPlayer, QBPlayer, ...).
---@field getIdentifier fun(): string
---@field getName fun(): string
---@field getFirstName fun(): string
---@field getLastName fun(): string
---@field getJob fun(): { name: string, label?: string, grade?: integer, grade_label?: string, onDuty?: boolean }
---@field getAccount fun(account: BridgeAccount): integer Current balance for the requested account.
---@field addAccountMoney fun(account: BridgeAccount, amount: integer): boolean Always returns true on success.
---@field removeAccountMoney fun(account: BridgeAccount, amount: integer): boolean Returns false when the account would go negative.
---@field addItem fun(itemName: string, count: integer, metadata?: table)
---@field removeItem fun(itemName: string, count: integer)
---@field getItemCount fun(itemName: string): integer
---@field hasLicense fun(licenseType: string): boolean
---@field grantLicense fun(licenseType: string): boolean
---@field getAdminRank fun(): string Returns the framework permission group (`"user"` by default).

---Client-side wrapper around the local player. Methods read/write live
---framework state.
---@class BridgeClientPlayer
---@field getData fun(): table Raw framework player data table.
---@field getIdentifier fun(): string
---@field getName fun(): string
---@field getJob fun(): string Current job name.
---@field getJobRank fun(): integer Current job grade level.
---@field getGang fun(): string Current gang name. ESX has no native gang so a placeholder is returned.
---@field getGangRank fun(): integer Current gang grade level. Always `0` on ESX.
---@field isOnJobDuty fun(): boolean
---@field isOnGangDuty fun(): boolean
---@field getAccount fun(accountName: BridgeAccount): integer
---@field revive fun()
---@field clearDeathStatus fun()

---Utility namespace for cross-cutting helpers that are not provider-backed.
---@class BridgeCore
---@field isStarted fun(resourceName: string): boolean Cached `GetResourceState` check.
---@field isAvailable fun(resourceName: string): boolean True when the resource is started OR any started resource declares `provide "<name>"` in its manifest.
---@field log fun(logType: BridgeLogType, msg: string, invoker?: string) Pretty-print to the FiveM console.
---@field setDebug fun(enabled: boolean) Toggle the `debug` log channel.
---@field checkVersion fun(resourceName?: string) Compare local resource version against the published manifest.

---Per-resource extension hook registry. Each consumer manages its own slot.
---@class BridgeCustom
---@field register fun(fnName: string, fn: function) Register a custom function for the invoking resource.
---@field call fun(fnName: string, ...): any Invoke a previously-registered function; returns nil when missing.
---@field has fun(fnName: string): boolean Whether `fnName` is registered for the invoking resource.

---Per-resource configuration with convar overrides.
---@class BridgeConfig
---@field register fun(config: table): table Resolve and return the effective config for the invoking resource.
---@field get fun(key: string, fallback?: any): any Read a single key, honoring convar overrides.

---SQL access through the active database provider (oxmysql by default).
---All methods are blocking (`await`-style).
---@class BridgeMysql
---@field query fun(query: string, params?: table): table[] Return every row.
---@field single fun(query: string, params?: table): table? Return the first row or nil.
---@field scalar fun(query: string, params?: table): any Return the first column of the first row.
---@field update fun(query: string, params?: table): integer Number of affected rows.
---@field insert fun(query: string, params?: table): integer Inserted id (or affected rows for batch inserts).
---@field prepare fun(query: string, params?: table): any
---@field rawExecute fun(query: string, params?: table): any
---@field transaction fun(queries: { query: string, values: table }[], params?: table): boolean Whether the transaction committed successfully.

---Server-side player lookups backed by the active framework.
---@class BridgePlayers
---@field getPlayerFromId fun(playerId: integer): BridgePlayer | false `false` when the source is not loaded.
---@field getPlayerFromIdentifier fun(identifier: string): BridgePlayer | false
---@field getIdFromIdentifier fun(identifier: string): integer | false
---@field getOnlinePlayers fun(): BridgePlayer[]
---@field getOnlinePlayersByJob fun(jobs: string | string[], onDutyOnly?: boolean): BridgePlayer[]
---@field getPlayersInZone fun(coords: vector3, radius: number, options?: { exceptions?: table<integer, boolean>, includeDead?: boolean }): BridgePlayer[]
---@field revive fun(source: integer): boolean
---@field clearDeathStatus fun(source: integer): boolean
---@field updateOfflinePlayerAccount fun(identifier: string, account: BridgeAccount, amount: integer): boolean Mutates the persisted account balance for offline players.

---Client-side wrapper around the local framework player. Mirrors
---`BridgeClientPlayer`.
---@class BridgeClientPlayers : BridgeClientPlayer

---Notification surface. Backed by the active notifications provider (esx,
---qb, ox_lib, ...).
---@class BridgeNotifications
---@field show fun(message: string, notificationType?: BridgeNotificationType, duration?: integer)
---@field help fun(message: string) Persistent help-text style notification.

---A single target interaction option, mirrored across qb-target, ox_target
---and qtarget. Fields that don't apply to the active provider are ignored.
---@class BridgeTargetOption
---@field name string?
---@field label string
---@field icon string?
---@field event string?
---@field serverEvent string?
---@field item string?
---@field job string?
---@field gang string?
---@field type string?
---@field action (fun(entity?: integer))?
---@field onSelect (fun(payload: { entity: integer }))?
---@field canInteract (fun(entity?: integer): boolean)?
---@field distance number?

---Targeting (eye/highlight) provider surface.
---@class BridgeTarget
---@field addLocalEntity fun(entity: integer, options: BridgeTargetOption[])
---@field removeLocalEntity fun(entity: integer, optionNames?: string[])
---@field addSphereZone fun(zone: { id: string, name?: string, coords: vector3, radius: number, distance?: number, debug?: boolean, options: BridgeTargetOption[] }): string? Returns the provider's internal zone id when available.
---@field removeZone fun(id: string)

---Server-side inventory surface; method semantics match ox_inventory and
---are emulated for QB / ESX. `slot` and `metadata` are optional everywhere.
---@class BridgeInventory
---@field addItem fun(source: integer, itemName: string, count: integer, metadata?: table): boolean
---@field removeItem fun(source: integer, itemName: string, count: integer, slot?: integer): boolean
---@field getItemCount fun(source: integer, itemName: string): integer
---@field hasItem fun(source: integer, itemName: string, count?: integer): boolean Defaults to 1.
---@field canCarryItem fun(source: integer, itemName: string, count: integer): boolean
---@field addAmmo fun(source: integer, ammoItem: string, weapon: string, amount: integer): boolean
---@field setItemMetadata fun(source: integer, itemName: string, slot: integer, metadata: table): boolean
---@field getItemBySlot fun(source: integer, slot: integer): table?
---@field supportsMetadata fun(): boolean Whether per-item metadata is preserved by the active provider.

---Client-side inventory lookup limited to the local player.
---@class BridgeClientInventory
---@field hasItem fun(itemName: string, amount?: integer): boolean

---Usable item registration. The callback fires when the player uses
---`itemName` from their inventory.
---@class BridgeUsableItems
---@field register fun(itemName: string, callback: fun(source: integer, item?: table))

---Society / job account ledger (ESX society, QB management, ...).
---@class BridgeSociety
---@field getMoney fun(jobName: string): integer
---@field addMoney fun(jobName: string, amount: integer): boolean
---@field removeMoney fun(jobName: string, amount: integer): boolean

---Persisted vehicle ownership. Plates are trimmed by every implementation.
---@class BridgeVehicleStorage
---@field getTableName fun(): string Underlying SQL table name.
---@field exists fun(plate: string): boolean
---@field getOwner fun(plate: string): string? Identifier of the owner, or nil.
---@field isOwnedBy fun(plate: string, owner: string): boolean
---@field setOwner fun(plate: string, newOwner: string): boolean
---@field getProperties fun(plate: string): table?
---@field setProperties fun(plate: string, properties: table): boolean
---@field getInfo fun(plate: string): { plate: string, owner: string, properties: table? }?
---@field getByOwner fun(owner: string): { plate: string, owner: string, properties: table? }[]
---@field create fun(owner: string, model: string, plate: string, properties?: table): boolean
---@field delete fun(plate: string): boolean
---@field renamePlate fun(oldPlate: string, newPlate: string): boolean

---Server-side vehicle helpers.
---@class BridgeVehiclesServer
---@field generateRandomPlate fun(format?: string): string Optional template — `A` -> uppercase letter, digit -> random digit, `^X` keeps `X` literal. Max length 8.

---Client-side vehicle property serialization.
---@class BridgeVehiclesClient
---@field getProperties fun(vehicle: integer): table
---@field applyProperties fun(vehicle: integer, properties: table)

---Vehicle key / ownership integration with key scripts (qb-vehiclekeys,
---wasabi_carlock, mrnewb, ...).
---@class BridgeVehicleKeys
---@field give fun(vehicle: integer, plate: string) Grant key ownership for the given plate.
---@field remove fun(plate: string) Revoke key ownership.

---Server-side player needs (hunger / thirst) bridged across frameworks.
---@class BridgeStatus
---@field feed fun(source: integer) Restore the player's hunger and thirst to full.
---@field setHunger fun(source: integer, value: number) `value` is the framework's native range (0-100 or 0-1000000 for ESX).
---@field setThirst fun(source: integer, value: number)

---Vehicle fuel level (0 - 100) through the active fuel provider.
---@class BridgeFuel
---@field get fun(vehicle: integer): number
---@field set fun(vehicle: integer, fuel: number)

---Dispatch payload understood by every supported MDT.
---@class BridgeDispatchPayload
---@field code? string Internal dispatch code.
---@field title? string Short title shown in the call list.
---@field description? string Long-form description.
---@field coords vector3 Incident location.
---@field jobs string[]? Limit the alert to specific jobs (police, ambulance, ...).
---@field [string] any

---Dispatch (911 / mdt) provider surface.
---@class BridgeDispatch
---@field send fun(payload: BridgeDispatchPayload)

---Options for a single `bridge.progress.run` call. Extra fields are
---forwarded to the underlying progress library.
---@class BridgeProgressOptions
---@field label string Text shown to the player.
---@field duration integer Duration in milliseconds.
---@field useWhileDead? boolean
---@field canCancel? boolean
---@field animation? table
---@field [string] any

---Progress bar provider (ox_lib, native, ...).
---@class BridgeProgress
---@field run fun(options: BridgeProgressOptions): boolean Returns true when the bar completed, false when cancelled.

---Consumer-facing root table fetched through
---`exports.lyre_bridge:getBridge()`. Modules are populated lazily; methods
---unknown to the active provider return `nil` silently.
---@class Bridge
---@field core BridgeCore
---@field custom BridgeCustom
---@field config BridgeConfig
---@field mysql BridgeMysql
---@field players BridgePlayers | BridgeClientPlayers
---@field status BridgeStatus
---@field notifications BridgeNotifications
---@field target BridgeTarget
---@field inventory BridgeInventory | BridgeClientInventory
---@field usable_items BridgeUsableItems
---@field society BridgeSociety
---@field vehicle_storage BridgeVehicleStorage
---@field vehicles BridgeVehiclesServer | BridgeVehiclesClient
---@field vehicle_keys BridgeVehicleKeys
---@field fuel BridgeFuel
---@field dispatch BridgeDispatch
---@field progress BridgeProgress
