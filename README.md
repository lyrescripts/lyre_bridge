# lyre_bridge

`lyre_bridge` is the shared compatibility core for the refactored Lyre resource copy.

It provides:
- deterministic bridge auto detection with aliases for ESX, QBCore, standalone and example/custom bridges;
- one central compatibility folder per Lyre resource;
- central shared config for repeated options such as locale, bridge, update checks, background blur and interact system;
- lazy modules that load only when a script asks for them;
- wrapped bridge calls with structured errors instead of silent failures;
- shared client modules for common features such as notifications, target, vehicle keys, fuel and progress;
- automatic SQL preparation from the central resource registry;
- framework-specific SQL support with retro compatibility;
- idempotent migration tracking in `lyre_bridge_migrations`;
- open `custom/client`, `custom/server`, and `resources/<resource>` folders for third-party compatibility.

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

Resource adapters should only define:

- `init()` for framework startup and shared objects;
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

The normalized player wrapper exposes `source`, `raw`, `getIdentifier()`, `getName()`, `getFirstName()`, `getLastName()`, `showNotification(...)`, `getAccount(account)`, `removeAccountMoney(account, amount)` and `addAccountMoney(account, amount)`.

That means repeated payment and identity code should not be copied into new adapters.
Adapters should keep only the parts that are genuinely resource-specific, such as licenses, inventory rules, admin groups, vehicle persistence, custom society accounting or offline SQL updates.

Resource layout:

```text
lyre_bridge/
  imports/
  server/
  schemas/
  custom/
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

Every `resources/<resource>/resource.lua` registers that resource in the core:
- `bridge.client` and `bridge.server` list the open adapter files;
- `sql.files` lists always-on SQL files;
- `sql.frameworkFiles` lists framework-specific SQL files;
- `requiresTables` lets optional SQL skip cleanly when a legacy table is missing.

## Adding a resource

1. Create `resources/<resource>/resource.lua` and register the resource with `LyreBridge.registerResource(...)`.
2. Put common SQL in `resources/<resource>/sql/*.sql`, then reference it from `sql.files`.
3. Put ESX/QBCore-specific SQL in separate files and reference them from `sql.frameworkFiles`.
4. Put only framework-specific adapter code in `bridge/client/*.lua` and `bridge/server/*.lua`.
5. In the resource `fxmanifest.lua`, import shared, client and server bridge files before the resource scripts that call `bridge`.
6. In the resource, call `setupClientBridge()` and `setupServerBridge()` once during startup.

New adapters should first rely on the defaults injected by `imports/client.lua` and `imports/server.lua`.
Add adapter methods only when the resource needs a different behavior or a feature the central modules cannot safely guess.

## Runtime flow

1. `@lyre_bridge/imports/shared.lua` creates the local `LyreBridge` runtime inside the consuming resource, loads the central config, reads convars, and exposes the bridge registry helpers.
2. The resource config is wrapped with `LyreBridge.createResourceConfig(...)`, so common values such as `locale`, `bridge`, `backgroundBlur` and `interactSystem` can come from global or per-resource convars.
3. Framework adapter files populate `_G.bridge` with candidates such as `ESX`, `QBCORE`, `QBOX`, `STANDALONE` or `EXAMPLE`.
4. The resource calls `setupClientBridge()` or `setupServerBridge()`. These wrappers delegate to `LyreBridge.setupClientResourceBridge(Config)` and `LyreBridge.setupServerResourceBridge(Config)`.
5. `LyreBridge.setupBridge(...)` selects the configured bridge or auto-detects one, calls its `init()`, validates required methods, decorates the selected bridge with shared defaults, then replaces `_G.bridge` with the active adapter.

Server startup also calls `LyreBridge.prepareResourceSql(...)` before bridge setup.
That function resolves the SQL files registered for the resource, picks the framework-specific SQL branch when needed, applies migrations once per checksum, and records the result in `lyre_bridge_migrations`.

## Scaling notes

- Resource state checks are cached through `lyre_bridge:stateCacheMs` to avoid repeated `GetResourceState` calls from common modules.
- Client modules are lazy: target, notifications, fuel, vehicle keys and progress are only created when a resource calls the matching bridge method.
- SQL is idempotent: `CREATE TABLE` and `INSERT INTO` statements are normalized, guarded `ALTER TABLE ... ADD ... IF NOT EXISTS` clauses are handled safely, and optional SQL can be skipped when required legacy tables are missing.
- Per-resource setup is idempotent, so repeated `setupClientBridge()` or `setupServerBridge()` calls return the already selected bridge instead of re-running SQL or framework init.
- Keep resource adapters small. Put common behavior in `imports/client.lua`, `imports/server.lua` or shared modules; keep adapters for framework-specific resource contracts.

Qbox is still supported by resources that ship Qbox adapters, but it is not part
of the global auto-detect order until every resource has matching Qbox bridge
files. Resources such as `lyre_deathscreen` can opt in with
`Config.bridgeAutoDetectOrder`.

Every refactored resource depends on `lyre_bridge` and imports:
- `@lyre_bridge/imports/shared.lua` in shared scripts, before the resource config;
- `@lyre_bridge/imports/client.lua` on the client;
- `@lyre_bridge/imports/server.lua` on the server;
- `@lyre_bridge/resources/<resource>/bridge/client/*.lua` for client bridge adapters;
- `@lyre_bridge/resources/<resource>/bridge/server/*.lua` for server bridge adapters.

Useful convars:

```cfg
set lyre_bridge:autoSql true
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
```

The original `script` directory is untouched. This refactored copy lives in `script_lyre_bridge`.
