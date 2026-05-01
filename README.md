# lyre_bridge

`lyre_bridge` is the shared compatibility core for the refactored Lyre resource copy.

It provides:
- deterministic bridge auto detection with aliases for ESX, QBCore, Qbox, standalone and example/custom bridges;
- one central compatibility folder per Lyre resource;
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

Every refactored resource depends on `lyre_bridge` and imports:
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
```

Manual SQL command:

```cfg
lyre_bridge_sql lyre_garage force ESX
lyre_bridge_sql lyre_garage force QBCORE
lyre_bridge_sql lyre_fuel force ESX
```

The original `script` directory is untouched. This refactored copy lives in `script_lyre_bridge`.
