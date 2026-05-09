# lyre_bridge

`lyre_bridge` is the shared compatibility core for the Lyre resource pack.

It provides:
- deterministic bridge auto detection with aliases for ESX, QBCore, Qbox, standalone and example/custom bridges;
- one central compatibility folder per Lyre resource;
- convention-first resource discovery, so each resource usually has a one-line identity file instead of manual file lists;
- runtime adapter loading from the central resource registry, so manifests do not duplicate framework file lists;
- active bridge info tracking per resource and side, while keeping `_G.bridge` for existing resource code;
- default ESX, QBCore, Qbox, Standalone and Example bridge candidates, so resources do not need boilerplate adapters just to fetch framework objects;
- central shared config for repeated options such as locale, bridge, update checks, background blur and interact system;
- lazy modules that load only when a script asks for them;
- provider registries for third-party integrations such as fuel, vehicle keys, inventory, usable items, society accounts and offline accounts;
- thin import entrypoints that load smaller shared, client and server modules;
- a dedicated resource registry module with a runtime consistency check;
- wrapped bridge calls with structured errors instead of silent failures;
- automatic bridge contract inference from loaded adapters, followed by strict selected-bridge validation;
- shared client modules for common features such as notifications, target, vehicle keys, fuel and progress;
- client inventory item checks for context/target visibility;
- automatic SQL preparation from the central resource registry;
- framework-specific SQL support with retro compatibility;
- idempotent migration tracking in `lyre_bridge_migrations`;
- open `custom/client`, `custom/server`, and `resources/<resource>` folders for third-party compatibility.

## Release installation

Required base resources:

- `oxmysql`
- `lyre_bridge`

`ox_lib` is **not** required by `lyre_bridge` itself; only specific consumer
resources depend on it (currently `lyre_fuel` and `lyre_illegalmissions`).
Their own `dependencies` block handles that.

Start the framework and third-party integrations first, then start the Lyre pack in this order:

```cfg
ensure oxmysql
ensure ox_lib            # only required if any consumer below depends on it
ensure lyre_bridge

ensure lyre_context
ensure lyre_context-defaults
ensure lyre_boatschool
ensure lyre_drivingschool
ensure lyre_flightschool
ensure lyre_carrental
ensure lyre_carwash
ensure lyre_fuel
ensure lyre_garage
ensure lyre_hunting
ensure lyre_illegalmissions
ensure lyre_tennis
```

`lyre_illegalmissions` is the core illegal mission hub. Its official DLC resources
(`atm`, `cartheft`, `gofast`, `moneytruck`, `murderer`) register through that parent
resource and can be installed as a full set or individually. When
`Config.autoStartDLCs` is enabled in `lyre_illegalmissions`, installed DLCs are
started automatically and missing non-strict DLCs are skipped with a warning.

Optional integrations are detected through providers when their resources are started:
ESX, QBCore, Qbox, `ox_inventory`, `qb-inventory`, `qs-inventory`, target systems,
notify systems, progress bars, fuel, vehicle keys, society accounts, dispatch and logs.
Force or disable a provider with the convars documented below when auto-detection is not desired.

SQL is prepared automatically when `lyre_bridge:autoSql` is enabled. The bridge runs the
registered SQL files once per checksum and records applied migrations in
`lyre_bridge_migrations`. If automatic SQL is disabled, import the SQL files from
`lyre_bridge/resources/<resource>/sql/` manually before starting the dependent resource.
MySQL event statements are skipped by default because many hosts disable the required
EVENT privilege; enable `lyre_bridge:autoSqlEvents` only when the database supports it.

Recommended production convars:

```cfg
set lyre_bridge:autoSql true
set lyre_bridge:autoSqlEvents false
set lyre_bridge:sqlStrict false
set lyre_bridge:debug false
set lyre_bridge:failHard false
setr lyre_bridge:bridge auto_detect
setr lyre_bridge:locale en
setr lyre_bridge:interact marker
```

Troubleshooting checklist:

- If a resource cannot find `bridge`, confirm `lyre_bridge` starts first and the resource manifest imports `@lyre_bridge/imports/shared.lua`, `@lyre_bridge/imports/client.lua`, and `@lyre_bridge/imports/server.lua`.
- If a resource identity looks wrong, run `lyre_bridge_resource <resource>` and confirm the generated bridge and SQL counts.
- If inventory, target, dispatch, fuel or vehicle keys do not bind to the expected resource, enable `lyre_bridge:debug true` and force the provider with the matching convar.
- If SQL is skipped, run `lyre_bridge_check`, inspect the registered resource SQL files, then run `lyre_bridge_sql <resource> force <framework>` only when you need a manual framework branch.
- If SQL ran before and you need the recorded result, run `lyre_bridge_sql_status <resource>`.
- If a dependency is optional, the bridge should fall back quietly or log a clear warning. If it is required, keep it in the resource `dependencies` block.

## Common client bridge contract

Common client behavior belongs in `imports/client.lua`, not in every resource adapter.
`imports/shared.lua` injects these defaults after the selected framework bridge has been loaded:

- `showNotification(message, type, duration)`
- `showHelpNotification(message)`
- `targetAddLocalEntity(entity, options)`
- `targetRemoveEntity(entity, optionNames)`
- `targetRemoveLocalEntity(entity, optionNames)`
- `targetAddSphereZone(options)` or `targetAddSphereZone(name, coords, radius, options)`
- `targetRemoveZone(id)`
- `giveVehicleKeys(plate, netId, options)` or `giveVehicleKeys(netId)`
- `removeVehicleKeys(plate, options)`
- `setFuel(vehicleOrNetId, fuel)`
- `getFuel(vehicleOrNetId)`
- `progress(options)` or `progress(duration, label, options)`
- `hasItem(itemName, amount)`
- `sendDispatchAlert(payload, options)`

ESX, QBCore, Qbox and Example candidates are registered by the core. A resource does not need adapter files just to detect a framework or fetch the shared object.
When an adapter only adds resource methods, use `LyreBridge.bridgeCandidate("QBOX")` and the core will hydrate missing detection/init defaults.

Resource adapters should only define:

- custom `init()` logic when this resource needs more than the default framework object;
- resource-specific methods such as vehicle properties, player data, groups or inventory helpers;
- overrides only when a resource genuinely needs behavior different from the shared module.

The target module supports `ox_target`, `qb-target` and `qtarget`.
The vehicle key and fuel modules try known providers first, then fall back to native behavior where that makes sense.

## Common server bridge contract

Common server player behavior belongs in `imports/server.lua`.
The server `players` module normalizes ESX, QBCore and Qbox player access and injects these defaults when an adapter does not define them:

- `getPlayerFromId(playerId)`
- `getIdFromIdentifier(identifier)`
- `getPlayerFromIdentifier(identifier)`
- `removePlayerMoney(playerId, account, amount)`
- `getPlayerIdentifier(playerId)`
- `getIdentifierFromSource(playerId)`
- `getPlayerName(playerId)` returning `firstname, lastname`
- `getPlayerDisplayName(playerId)`
- `showNotification(playerId, message, type, duration)`
- `sendDispatchAlert(payload, options)`

The normalized player wrapper exposes `source`, `raw`, `getIdentifier()`, `getName()`, `getFirstName()`, `getLastName()`, `showNotification(...)`, `getAccount(account)`, `removeAccountMoney(account, amount)` and `addAccountMoney(account, amount)`.
The inventory provider module also normalizes `addItem(...)`, `removeItem(...)`, `getItemCount(...)`, `hasItem(...)`, `canCarryItem(...)`, `addAmmo(...)`, `setItemMetadata(...)` and `getItemBySlot(...)` unless an adapter explicitly opts into its own inventory implementation.

That means repeated payment and identity code should not be copied into new adapters.
Adapters should keep only the parts that are genuinely resource-specific, such as licenses, inventory rules, admin groups, vehicle persistence, custom society accounting or offline SQL updates.

Resource layout:

```text
lyre_bridge/
  imports/
    shared.lua
    shared/*.lua
    client.lua
    client/*.lua
    server.lua
    server/*.lua
  server/
  schemas/
  custom/
    client/*.lua
    server/*.lua
  examples/
    client/*.lua
    server/*.lua
  resources/
    lyre_garage/
      resource.lua
      bridge/client/*.lua
      bridge/server/*.lua
      sql/import_esx.sql
      sql/import_qb.sql
    lyre_fuel/
      resource.lua
      bridge/client/*.lua
      bridge/server/*.lua
      sql/import.sql
      sql/inventory_items/esx.sql
    ox_target/
      resource.lua
      bridge/client/client.lua
```

Every `resources/<resource>/resource.lua` registers that resource in the core.
For normal resources the file is intentionally tiny:

```lua
LyreBridge.registerResource("lyre_fuel")
```

The registry then auto-discovers:

- `bridge/client/esx.lua`, `qbox.lua`, `qbcore.lua`, `standalone.lua`, `example.lua`;
- legacy side-prefixed names (`cl_esx.lua`, `sv_esx.lua`) for backwards compatibility;
- matching `bridge/server/<framework>.lua`;
- target shims such as `bridge/client/client.lua`;
- common SQL from `sql/import.sql`;
- framework SQL from `sql/import_esx.sql`, `sql/import_qb.sql`, `sql/import_qbcore.sql`, and `sql/import_qbox.sql`;
- optional inventory seed SQL from `sql/inventory_items/esx.sql`, guarded by the `items` table check.

The registry intentionally has no `locked` flag. Packaging and escrow behavior
come from each resource manifest, so the bridge registry only describes files
that the runtime must load or validate.

See `docs/resources.md` for the short resource authoring guide.

## Adding a resource

1. Create `resources/<resource>/resource.lua` with `LyreBridge.registerResource("<resource>")`.
2. Put common SQL in `resources/<resource>/sql/import.sql`.
3. Put framework SQL in `sql/import_esx.sql`, `sql/import_qb.sql`, `sql/import_qbcore.sql`, or `sql/import_qbox.sql`.
4. Put framework-specific adapter code in convention files under `bridge/client/` and `bridge/server/` only when the resource needs custom behavior.
5. In the resource `fxmanifest.lua`, import only `@lyre_bridge/imports/shared.lua`, `@lyre_bridge/imports/client.lua`, and `@lyre_bridge/imports/server.lua` before scripts that call `bridge`.
6. In the resource, call `setupClientBridge()` and `setupServerBridge()` once during startup.
7. Run `tools\check_bridge_pack.ps1`.

New adapters should first rely on the default framework candidates and the defaults injected by `imports/client.lua` and `imports/server.lua`.
Add adapter methods only when the resource needs a different behavior or a feature the central modules cannot safely guess.

The setup functions load `resources/<resource>/resource.lua`, generate the resource identity, then load the bridge files discovered for the requested side. Manual file lists are still supported for uncommon paths, but convention files should be the default.
When a resource must not run without custom files, declare that explicitly:

```lua
LyreBridge.registerResource("my_resource", {
    bridge = {
        required = { client = true, server = true },
    },
    sql = {
        required = true,
    },
})
```

## Adding a provider

Provider integrations should live in topic folders, not inside the module core:

```text
imports/client/fuel/providers/<provider>.lua
imports/client/inventory/providers/<provider>.lua
imports/client/vehicle_keys/providers/<provider>.lua
imports/server/inventory/providers/<provider>.lua
imports/server/usable_items/providers/<provider>.lua
imports/server/society/providers/<provider>.lua
imports/server/offline_accounts/providers/<provider>.lua
imports/client/dispatch/providers/<provider>.lua
imports/server/dispatch/providers/<provider>.lua
```

Register providers with `LyreBridge.registerProvider(side, moduleName, provider)`.
Providers should expose small methods such as `set`, `get`, `give`, `remove`, or `register`.
The module decides the contract; the provider file only contains resource-specific glue.
When several resources share the same export shape, keep the shared helper in one `shared.lua`
file and keep one small named provider file per supported resource.
Add the provider import once in `imports/client.lua` or `imports/server.lua`.

Example:

```lua
LyreBridge.registerProvider("client", "fuel", {
    name = "my_fuel",
    resource = "my_fuel",
    priority = 100,
    set = function(self, context, vehicle, fuel)
        exports["my_fuel"]:SetFuel(vehicle, fuel)
        return true
    end,
})
```

### Selecting or disabling providers

Providers are auto-selected by priority when their target resource is started.
For runtime troubleshooting or server-specific choices, use replicated convars
for client providers and normal convars for server providers:

```cfg
setr lyre_bridge:provider:fuel:force ox_fuel
setr lyre_bridge:provider:vehicleKeys:force qb-vehiclekeys
set  lyre_bridge:provider:inventory:force ox_inventory
set  lyre_bridge:provider:usableItems:force qbox
setr lyre_bridge:provider:client:dispatch:force cd_dispatch
set  lyre_bridge:provider:server:dispatch:force cd_dispatch

setr lyre_bridge:provider:fuel:disabled LegacyFuel,cdn-fuel
setr lyre_bridge:provider:vehicleKeys:disabled qs-vehiclekeys
set  lyre_bridge:provider:inventory:disabled qb
setr lyre_bridge:provider:client:dispatch:disabled ps-dispatch
set  lyre_bridge:provider:server:dispatch:disabled fd_dispatch
```

More specific keys win by scope because they are checked first:

```cfg
setr lyre_bridge:provider:client:fuel:force lyre_fuel
set  lyre_bridge:provider:server:inventory:force ox_inventory
setr lyre_bridge:provider:client:fuel:disabled LegacyFuel
```

Enable `lyre_bridge:debug true` to see which provider handled fuel, vehicle
keys, inventory, usable item, society, offline account, and dispatch calls.

## Custom examples

The `examples/client` and `examples/server` folders contain small topic-based examples.
They are not loaded by the manifest. Copy an example into `custom/client` or `custom/server`
only when that override should run on the server.
Use them as copy-paste templates for project-specific integrations such as notifications, targets, fuel, vehicle keys, progress, SQL wrappers, inventory, licenses, society accounts, offline accounts, usable items, callbacks and webhooks.

Keep custom code in small files by topic.
That makes updates safer because the core imports can change without overwriting project-specific integrations.

## Runtime flow

1. `@lyre_bridge/imports/shared.lua` creates the local `LyreBridge` runtime inside the consuming resource, then loads the smaller files in `imports/shared/*.lua`.
2. The resource config is wrapped with `LyreBridge.createResourceConfig(...)`, so common values such as `locale`, `bridge`, `backgroundBlur` and `interactSystem` can come from global or per-resource convars.
3. `@lyre_bridge/imports/client.lua` and `@lyre_bridge/imports/server.lua` load their own smaller modules from `imports/client/*.lua` and `imports/server/*.lua`.
4. The resource calls `setupClientBridge()` or `setupServerBridge()`. These wrappers load the resource identity from `lyre_bridge/resources/<resource>/resource.lua`, discover convention files, and load the adapter files for that side.
5. `LyreBridge.setupBridge(...)` adds default `ESX`, `QBCORE`, `QBOX`, `STANDALONE` and `EXAMPLE` candidates, then merges any resource adapters discovered from the registry.
6. It infers required resource-specific methods from loaded adapters, selects the configured bridge or auto-detects one, calls its `init()`, decorates it with shared defaults, validates the contract, then replaces `_G.bridge` with the active adapter.

Server startup calls `LyreBridge.prepareResourceSql(...)` after the server bridge has been loaded and validated.
That function resolves the SQL files discovered for the resource, uses the selected framework for the framework-specific SQL branch, applies migrations once per checksum, and records the result in `lyre_bridge_migrations`.

## Scaling notes

- Resource state checks are cached through `lyre_bridge:stateCacheMs` to avoid repeated `GetResourceState` calls from common modules, and the cache is invalidated on resource start/stop events.
- Client modules are lazy: target, notifications, fuel, vehicle keys and progress are only created when a resource calls the matching bridge method.
- SQL is idempotent: `CREATE TABLE` and `INSERT INTO` statements are normalized, guarded `ALTER TABLE ... ADD ... IF NOT EXISTS` clauses are handled safely, and optional SQL can be skipped when required legacy tables are missing.
- Per-resource setup is idempotent, so repeated `setupClientBridge()` or `setupServerBridge()` calls return the already selected bridge instead of re-running SQL or framework init.
- Keep resource adapters small. Put common behavior in `imports/client.lua`, `imports/server.lua` or shared modules; keep adapters for framework-specific resource contracts.

Qbox is part of the global auto-detect order. Resources only need explicit Qbox
files when they implement Qbox-specific behavior; simple framework setup comes
from the default bridge candidates.

Every refactored resource depends on `lyre_bridge` and imports:
- `@lyre_bridge/imports/shared.lua` in shared scripts, before the resource config;
- `@lyre_bridge/imports/client.lua` on the client;
- `@lyre_bridge/imports/server.lua` on the server.

Bridge adapter files are loaded by the setup functions from the central registry.

Useful convars:

```cfg
set lyre_bridge:autoSql true
set lyre_bridge:autoSqlEvents false
set lyre_bridge:sqlStrict false
set lyre_bridge:debug false
set lyre_bridge:failHard false
set lyre_bridge:wrapCalls true
set lyre_bridge:stateCacheMs 2500
setr lyre_bridge:locale en
setr lyre_bridge:bridge auto_detect
setr lyre_bridge:checkForUpdates true
setr lyre_bridge:backgroundBlur false
setr lyre_bridge:interact marker
```

Per-resource overrides can be set from the bridge namespace, for example:

```cfg
setr lyre_bridge:lyre_fuel:locale fr
setr lyre_bridge:lyre_garage:interact target
setr lyre_bridge:lyre_garage:sqlStrict true
```

Legacy convars such as `lyre_fuel:locale`, `lyre_garage:interact` and
`lyre_illegalmissions:target` are still read for backwards compatibility.

Manual SQL command:

```cfg
lyre_bridge_sql lyre_garage force ESX
lyre_bridge_sql lyre_garage force QBCORE
lyre_bridge_sql lyre_fuel force ESX
lyre_bridge_sql lyre_tennis force ESX events
lyre_bridge_sql_status lyre_garage
```

Manual registry check:

```cfg
lyre_bridge_check
lyre_bridge_resource lyre_garage verbose
```

This bridge is the source of truth for shared Lyre compatibility modules and provider registrations.
