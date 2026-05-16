# lyre_bridge

Provider-based compatibility bridge for the Lyre resource pack. Exposes a flat
`bridge` table that consumer scripts call into, while the actual framework or
third-party integration is auto-detected at runtime from the providers
registered under `bridges/`.

## What it is

`lyre_bridge` is **the** integration layer. No Lyre consumer talks to ESX,
QBCore, qbx_core, ox_inventory, ox_target, ox_lib, oxmysql, dispatch scripts,
fuel scripts, vehicle-key scripts, etc. directly — they all call `bridge.X.Y`
and let this resource pick the correct provider.

What you get out of the box:

- **Single import line.** Consumers add `@lyre_bridge/imports.lua` as a
  `shared_script` and `bridge` becomes a global table available everywhere.
- **Flat-table bridge fetched through an export.** `bridge` is a plain table —
  no metatables — so it crosses FiveM's resource export boundary safely
  (metatables don't survive `__cfx_export_*` serialization).
- **Auto-discovery.** Every `bridges/<side>/<module>/<provider>.lua` calls
  `LyreBridge.registerProvider(side, module, name, priority)` and the engine
  walks the registry to expose every public method as `bridge.<module>.<method>`.
- **Lazy resolution.** A provider's `detect()` only runs on the first call to
  its module, then `init()` runs once, and the bridge caches the resolved
  provider for the rest of the runtime.
- **Convar overrides.** Force or disable a provider per side and module
  without touching the bridge code.
- **Per-resource configuration.** `bridge.config.register/get` reads global
  defaults plus per-resource convar overrides into a flat table.
- **Per-resource custom hooks.** `bridge.custom.register/has/call` lets a
  consumer expose extension points (custom refill missions, dispatch overrides,
  vehicle-deletion side effects) without polluting the bridge surface.
- **MySQL access.** `bridge.mysql.*` is the only place that depends on
  `oxmysql`; consumers don't ship the `@oxmysql/lib/MySQL.lua` import or list
  `oxmysql` in their `dependencies`.
- **Server-to-client relays.** Server code that needs the active client-side
  provider (notifications, revive) fires
  `TriggerClientEvent("lyre_bridge:<module>:<method>", source, …)` and the
  relay in `engine/client_relay.lua` routes it to `bridge.<module>.<method>`.

## Installation

Required base resource:

```cfg
ensure oxmysql           # used only by lyre_bridge itself, not by consumers
ensure lyre_bridge

# then your Lyre consumers in any order, e.g.
ensure lyre_context
ensure lyre_context-defaults
ensure lyre_carrental
ensure lyre_carwash
ensure lyre_fuel
ensure lyre_garage
ensure lyre_drivingschool
ensure lyre_flightschool
ensure lyre_boatschool
ensure lyre_hunting
ensure lyre_illegalmissions
ensure lyre_tennis
ensure lyre_deathscreen
```

`ox_lib` is **not** a hard requirement. Some consumers list it themselves
(currently `lyre_illegalmissions` for `lib.callback`); start it before those
consumers when relevant. `lyre_bridge` itself only uses ox_lib through its
optional `notifications` and `progress` providers.

## Repository layout

```
engine/
  bridge.lua          # exports `getBridge`, builds the flat `bridge` table
  client_relay.lua    # net events that bounce server → active client provider
  configuration.lua   # convar-overridable global / per-resource config
  custom.lua          # per-resource extension hook registry
  registry.lua        # LyreBridge.registerProvider(side, module, name, priority)
  resolver.lua        # detect/init/forced/disabled provider resolution
  version_check.lua   # bridge.core.checkVersion(resourceName?)

bridges/
  client/<module>/<provider>.lua
  server/<module>/<provider>.lua

resources/
  client/<resource>/<hook>.lua    # custom hook stubs for consumers
  server/<resource>/<hook>.lua

utils/
  log.lua             # bridge.core.log("info" | "warning" | "error" | "debug", msg)
  isStarted.lua       # bridge.core.isStarted / isAvailable
  setDebug.lua        # bridge.core.setDebug(true/false)

config.lua            # LyreBridge.config global defaults (locale, interact)
imports.lua           # `bridge = exports.lyre_bridge:getBridge()`
types.lua             # ---@meta LuaLS annotations for the public surface
fxmanifest.lua
```

## Bridge surface

Read `types.lua` for the full LuaLS-annotated contract. The modules currently
shipped:

### `bridge.core`

| Method | Description |
|---|---|
| `isStarted(resourceName)` | Cached `GetResourceState` check. |
| `isAvailable(resourceName)` | True when the resource is started **or** any started resource declares `provide "<name>"`. Use when you care about a surface being callable (e.g. `exports.ox_target:...`). |
| `log(logType, msg, invoker?)` | Pretty-print a colored line. `logType` is `"info"`, `"warning"`, `"error"`, or `"debug"`. |
| `setDebug(enabled)` | Toggle the `debug` log channel globally. |
| `checkVersion(resourceName?)` | Server-only. Compares the local version against the published manifest at `https://raw.githubusercontent.com/lyrescripts/versions/main/<resource>.json`. |

### `bridge.config`

```lua
Config = bridge.config.register({ ... })       -- merge resource defaults with global + convars
local locale = bridge.config.get("locale", "en")  -- read a single key
```

Global defaults live in `config.lua` (`LyreBridge.config.locale`, `interact`).
Convar overrides: `setr lyre_bridge:<key> <value>` (global) or
`setr lyre_bridge:<resourceName>:<key> <value>` (per-resource).

### `bridge.custom`

Per-resource extension hooks. Functions are keyed by the **invoking** resource.

```lua
-- consumer side
bridge.custom.register("customRefillFunction", function(stationId, water, soap, wax)
    -- override the default refill behavior
    return true
end)

-- bridge / shared code
if bridge.custom.has("customRefillFunction") then
    bridge.custom.call("customRefillFunction", ...)
end
```

Resource hooks already shipped under `resources/`:

- `server/lyre_carwash/customRefillFunction.lua` / `expressRefillAction.lua`
- `server/lyre_fuel/customRefillFunction.lua` / `expressRefillAction.lua` / `nonLiquidRefillAction.lua`
- `server/lyre_garage/onImpoundPayment.lua` / `onVehicleTransferPayment.lua`
- `client/lyre_garage/onVehicleDelete.lua` / `applyVehicleDeformation.lua` / `saveVehicleDeformation.lua`
- `server/lyre_illegalmissions/onMissionEnd.lua`

### `bridge.mysql` (server)

Blocking (`await`-style) wrappers around the active SQL provider (currently
`oxmysql`).

```lua
bridge.mysql.query(sql, params?)        -- table[]
bridge.mysql.single(sql, params?)       -- table? (first row)
bridge.mysql.scalar(sql, params?)       -- any (first column of first row)
bridge.mysql.update(sql, params?)       -- integer affected rows
bridge.mysql.insert(sql, params?)       -- integer insert id (or affected count)
bridge.mysql.prepare(sql, params?)      -- driver raw result
bridge.mysql.rawExecute(sql, params?)   -- driver raw result
bridge.mysql.transaction(queries, ?)    -- boolean committed
```

### `bridge.players`

Server-side returns wrappers around the framework's xPlayer / QBPlayer.
Client-side targets the local player.

**Server:**

```lua
local player = bridge.players.getPlayerFromId(source)
-- wrapper:
player.source            -- integer
player.raw               -- native xPlayer / QBPlayer
player.getIdentifier()
player.getName(), getFirstName(), getLastName()
player.getJob()          -- { name, label, grade, grade_label?, onDuty? }
player.getAccount(account)
player.addAccountMoney(account, amount)
player.removeAccountMoney(account, amount)
player.addItem(itemName, count, metadata?)
player.removeItem(itemName, count)
player.getItemCount(itemName)
player.hasLicense(licenseType)      -- maps "car" → "drive" (ESX) / "driver" (QB), etc.
player.grantLicense(licenseType)
player.getAdminRank()               -- framework permission group ("user" by default)
```

Plus the module-level helpers:

```lua
bridge.players.getPlayerFromIdentifier(id)
bridge.players.getIdFromIdentifier(id)
bridge.players.getOnlinePlayers()
bridge.players.getOnlinePlayersByJob(jobs, onDutyOnly?)
bridge.players.getPlayersInZone(coords, radius, { exceptions?, includeDead? })
bridge.players.revive(source)
bridge.players.clearDeathStatus(source)
bridge.players.updateOfflinePlayerAccount(identifier, account, amount)
```

**Client:**

```lua
bridge.players.getData()
bridge.players.getIdentifier()
bridge.players.getName()
bridge.players.getJob()       -- STRING (current job name)
bridge.players.getJobRank()
bridge.players.getGang()      -- STRING (ESX returns a stable placeholder)
bridge.players.getGangRank()
bridge.players.isOnJobDuty()
bridge.players.isOnGangDuty()
bridge.players.getAccount(account)
bridge.players.revive()       -- full native + framework-specific death cleanup
bridge.players.clearDeathStatus()
```

### `bridge.notifications` (client)

```lua
bridge.notifications.show(message, type?, duration?)
bridge.notifications.help(message)
```

From the server, use the relay event:

```lua
TriggerClientEvent("lyre_bridge:notifications:show", source, message, type?, duration?)
```

Providers: `ox_lib`, `esx`, `qbcore`, `qbox`, `gta` (native fallback).

### `bridge.target` (client)

```lua
bridge.target.addLocalEntity(entity, optionsArray)
bridge.target.removeLocalEntity(entity, optionNames?)
bridge.target.addSphereZone({ id, coords, radius, debug?, options })
bridge.target.removeZone(id)
```

`optionsArray` is an array of `BridgeTargetOption`s — fields that don't apply
to the active provider (e.g. `gang` on ox_target) are ignored. Providers:
`ox_target`, `qb_target`, `qtarget`.

### `bridge.progress` (client)

```lua
local completed = bridge.progress.run({
    duration = 5000,
    label = "Doing the thing",
    canCancel = true,
    -- any provider-specific extra is forwarded as-is (anim, useWhileDead, …)
})
```

Returns `true` when the bar finished, `false` when cancelled. Providers:
`ox_lib` (with `circle = true` for the radial variant), `native` fallback.

### `bridge.inventory`

**Server:**

```lua
bridge.inventory.addItem(source, itemName, count, metadata?)
bridge.inventory.removeItem(source, itemName, count, slot?)
bridge.inventory.getItemCount(source, itemName)
bridge.inventory.hasItem(source, itemName, count?)
bridge.inventory.canCarryItem(source, itemName, count)
bridge.inventory.addAmmo(source, ammoItem, weapon, amount)
bridge.inventory.setItemMetadata(source, itemName, slot, metadata)
bridge.inventory.getItemBySlot(source, slot)
bridge.inventory.supportsMetadata()
```

**Client:**

```lua
bridge.inventory.hasItem(itemName, amount?)
```

Providers: `ox_inventory`, `esx`, `qb`, `qs_inventory`, `qbox` (client only).

### `bridge.usable_items` (server)

```lua
bridge.usable_items.register(itemName, function(source, item)
    -- handler
end)
```

Providers: `ox_inventory`, `qs_inventory`, `esx`, `qb`, `qbox`.

### `bridge.society` (server)

```lua
bridge.society.getMoney(jobName)
bridge.society.addMoney(jobName, amount)
bridge.society.removeMoney(jobName, amount)
```

Providers: `esx` (via `esx_addonaccount`), `qb` (via the management/banking
script).

### `bridge.status` (server)

Player needs (hunger/thirst) bridged across frameworks.

```lua
bridge.status.feed(source)
bridge.status.setHunger(source, value)   -- native range (0-100 or 0-1e6 on ESX)
bridge.status.setThirst(source, value)
```

Providers: `esx`, `qbcore`, `qbox`.

### `bridge.vehicle_storage` (server)

Persistent vehicle ownership table abstraction (`owned_vehicles` for ESX,
`player_vehicles` for QBCore / qbx_core).

```lua
bridge.vehicle_storage.getTableName()                       -- "owned_vehicles" / "player_vehicles"
bridge.vehicle_storage.exists(plate)
bridge.vehicle_storage.getOwner(plate)
bridge.vehicle_storage.isOwnedBy(plate, owner)
bridge.vehicle_storage.setOwner(plate, newOwner)
bridge.vehicle_storage.getProperties(plate)                 -- parsed JSON
bridge.vehicle_storage.setProperties(plate, properties)
bridge.vehicle_storage.getInfo(plate)                       -- { plate, owner, properties }
bridge.vehicle_storage.getByOwner(owner)
bridge.vehicle_storage.create(owner, model, plate, properties?)
bridge.vehicle_storage.delete(plate)
bridge.vehicle_storage.renamePlate(oldPlate, newPlate)
```

### `bridge.vehicles`

**Server:**

```lua
bridge.vehicles.generateRandomPlate(format?)
-- format template:
--   A     → random uppercase letter
--   digit → random 0-9
--   ^X    → keep X literal
-- length capped to 8
```

**Client:**

```lua
bridge.vehicles.getProperties(vehicle)
bridge.vehicles.applyProperties(vehicle, properties)
```

Providers: per-framework client (ESX / QBCore / qbox) + a universal server
fallback.

### `bridge.vehicle_keys` (client)

```lua
bridge.vehicle_keys.give(vehicle, plate)
bridge.vehicle_keys.remove(plate)
```

Providers: `qb_vehiclekeys`, `qbx_vehiclekeys`, `qs_vehiclekeys`,
`wasabi_carlock`, `mrnewb_vehiclekeys`, `mk_vehiclekeys`, `renewed_vehiclekeys`,
`tgiann_hotwire`, `ti_vehicle_keys`, `t1ger_keys`, `fivecode_carkeys`,
`f_real_car_keys_system`.

### `bridge.fuel` (client)

```lua
bridge.fuel.get(vehicle)        -- number (0-100)
bridge.fuel.set(vehicle, level)
```

Providers: `lyre_fuel`, `ox_fuel`, `legacy_fuel`, `cdn_fuel`, `lj_fuel`,
`lc_fuel`, `ti_fuel`, `qb_fuel`, `qb_sna_fuel`, `esx_sna_fuel`, `ps_fuel`,
`nd_fuel`, `rcore_fuel`, `renewed_fuel`, `bigdaddy_fuel`, `frfuel`, `native`
fallback.

### `bridge.dispatch`

```lua
bridge.dispatch.send({
    code = "10-30",
    title = "Robbery in progress",
    description = "...",
    coords = vector3(x, y, z),
    jobs = { "police" },
    -- extra fields forwarded as-is
})
```

Providers: `ps_dispatch`, `cd_dispatch`, `fd_dispatch`, `lb_tablet`,
`rcore_dispatch`, `zero_r_dispatch` (server) / `ps_dispatch`, `cd_dispatch`,
`qs_dispatch`, `rcore_dispatch`, `core_dispatch`, `tk_dispatch`,
`codem_dispatch` (client).

## Configuration & convars

Set in `server.cfg`:

```cfg
# global defaults (apply to every consumer unless overridden)
setr lyre_bridge:locale fr
setr lyre_bridge:interact target

# per-resource override (highest priority)
setr lyre_bridge:lyre_carwash:interact marker

# pin a specific provider (per side, optionally per module)
setr lyre_bridge:provider:client:notifications:force ox_lib
setr lyre_bridge:provider:client:fuel:force ox_fuel
setr lyre_bridge:provider:server:dispatch:force ps_dispatch

# blacklist a provider so detection skips it
setr lyre_bridge:provider:client:notifications:disabled qbcore,esx
setr lyre_bridge:provider:client:fuel:disabled native
```

Naming convention:

- `lyre_bridge:provider:<side>:<module>:force <providerName>` — force the
  named provider on that side/module.
- `lyre_bridge:provider:<module>:force <providerName>` — force on any side.
- `lyre_bridge:provider:<side>:<module>:disabled <a,b,...>` — comma- or
  space-separated blacklist.
- `lyre_bridge:provider:<module>:disabled <a,b,...>` — same, any side.

## Server → client relays

Server code that needs the **client** side of the bridge (the user's
notification UI, the local revive flow) fires
`TriggerClientEvent("lyre_bridge:<module>:<method>", source, …)` and the
client relay in `engine/client_relay.lua` calls
`bridge.<module>.<method>(...)`. Currently shipped:

```lua
TriggerClientEvent("lyre_bridge:notifications:show", source, message, type?, duration?)
TriggerClientEvent("lyre_bridge:players:revive", source)
```

This keeps server code stateless (no need to remember which notification
provider the player has) and avoids piggy-backing on a specific framework's
notify event.

## Adding a new provider

1. Pick the right side and module (e.g. `server/dispatch`).
2. Drop a file in `bridges/<side>/<module>/<your_name>.lua`.
3. Register it and implement the module's contract from `types.lua`.

Skeleton:

```lua
local provider = LyreBridge.registerProvider("server", "dispatch", "my_dispatch", 50)

---@return boolean
function provider:detect()
    return bridge.core.isStarted("my_dispatch")
end

---@param payload BridgeDispatchPayload
function provider:send(payload)
    exports["my_dispatch"]:CreateAlert({
        code = payload.code,
        message = payload.message or payload.description,
        coords = payload.coords,
        jobs = payload.jobs or { "leo" },
    })
end
```

Lower `priority` wins. The default is `100`; framework-tied providers usually
register at `10` so they're picked when their framework is the active one.
Auto-discovery picks up any new file in `bridges/**/*.lua` on resource start —
no manifest edits required.

The engine never holds onto the provider returned by `registerProvider` —
methods are resolved through `LyreBridge.resolveProvider` at call time, so
late additions and convar overrides take effect immediately.

## Adding a new consumer

In your resource:

```lua
-- fxmanifest.lua
shared_scripts({
    "@lyre_bridge/imports.lua",
    "config.lua",
    -- ...
})

dependencies({
    "lyre_bridge",
})
```

```lua
-- config.lua
Config = bridge.config.register({})
-- Config inherits locale, interact, etc. from the bridge defaults
-- plus any setr lyre_bridge:<your_resource>:<key> <value> overrides.
```

Then call `bridge.X.Y` anywhere — `bridge` is global once `imports.lua` runs.

## License

Internal compatibility core for the Lyre resource pack. See `fxmanifest.lua`
for version and authoring info.
