# lyre_bridge

Compatibility bridge for the Lyre resource pack. Consumer scripts call into a
flat `bridge` table and the actual framework or third-party integration is
auto-detected at runtime from the providers under `bridges/`.

## Installation

```cfg
ensure oxmysql
ensure lyre_bridge

# then your Lyre consumers
ensure lyre_context
ensure lyre_fuel
# ...
```

Only `oxmysql` is required. `ox_lib` is optional and pulled in by a few
consumers that depend on it (e.g. `lyre_illegalmissions`).

## Repository layout

```
engine/                 core: provider registry, resolver, bridge builder
bridges/<side>/<module>/<provider>.lua    auto-discovered providers
resources/<side>/<resource>/<hook>.lua    optional per-resource extension hooks

imports.lua             single shared_script that consumers load
config.lua              global defaults (locale, interact)
types.lua               LuaLS annotations describing the public surface
```

## Configuration

Set in `server.cfg`. All knobs are convars. The values below match the
defaults; only override what you actually want to change.

```cfg
# global defaults applied to every consumer
setr lyre_bridge:locale en
setr lyre_bridge:interact marker

# per-resource override (wins over the global default)
setr lyre_bridge:lyre_carwash:interact marker

# pin a specific provider (per side, or any side)
setr lyre_bridge:provider:client:notifications:force ox_lib
setr lyre_bridge:provider:client:fuel:force ox_fuel
setr lyre_bridge:provider:server:dispatch:force ps_dispatch

# blacklist a provider so detection skips it
setr lyre_bridge:provider:client:notifications:disabled qbcore,esx

# bridge's startup version check pipeline (keep this on to get update warnings)
setr lyre_bridge:checkForUpdates true
```

## Adding a consumer

In your resource's `fxmanifest.lua`:

```lua
shared_scripts({
    "@lyre_bridge/imports.lua",
    "config.lua",
    -- ...
})

dependencies({
    "lyre_bridge",
})
```

In `config.lua`:

```lua
Config = bridge.config.register({})
```

Then call `bridge.X.Y` anywhere. The `bridge` global is available once
`imports.lua` runs. The full surface is annotated in `types.lua`.

## Adding a provider

Drop a file in `bridges/<side>/<module>/<your_name>.lua`:

```lua
local provider = LyreBridge.registerProvider("server", "dispatch", "my_dispatch", 50)

function provider:detect()
    return bridge.core.isStarted("my_dispatch")
end

function provider:send(payload)
    exports["my_dispatch"]:CreateAlert(payload)
end
```

Lower `priority` wins. Framework-tied providers usually register at `10`;
the default fallback is `100`. New files are picked up on resource start, no
manifest edit needed.

## Gang integrations

QBCore and QBX expose the player's primary gang through the server player wrapper's
`getGang()` method. It returns a name, numeric grade and the available framework
fields. The native grade table is kept intact in the framework player data.

ESX has no native gang system. The default client and server providers return
`none` with grade zero; the client reports no gang duty. To integrate a custom
gang builder or an installation using `job2`, adapt these public provider methods
to that installation's actual API and data:

- `bridges/server/players/esx.lua`: the returned player's `getGang()` closure.
- `bridges/client/players/esx.lua`: `getGang()`, `getGangRank()` and `isOnGangDuty()`.

The server adapter must derive membership and grade from trusted server data.
The client adapter controls visible interactions and should read the matching
synced state. A second job represents a gang only when the installation explicitly
uses it that way. Return `none` when no membership exists. The public return shape
is documented in `types.lua`.

## QB inventory and society dependencies

The QB inventory provider checks capacity through `qb-inventory:CanAddItem` and
requires that resource for capacity checks. Unsupported or unloaded inventories
fail the check. Metadata updates validate the requested slot and item before
saving an updated inventory; quantities include every matching slot.

The QB society provider requires `qb-banking` for account balances and transfers.
Current `qb-management` handles employee management and does not expose the
financial exports used by this provider. It is not selected as a banking fallback.

## Extension hooks

Files under `resources/<side>/<resource>/` are customization templates shipped as
assets. They are not executed automatically. Register a hook explicitly in the
consumer's appropriate client or server script after `@lyre_bridge/imports.lua`:

```lua
bridge.custom.register("onVehicleDelete", function(vehicle)
    -- Perform integration-specific cleanup for this vehicle here.
end)
```

Registration is scoped to the invoking consumer and accepts Lua callbacks across
the CFX resource boundary. Match the hook's side, arguments and expected return
value to its call site. Replacement hooks must implement their full behavior and
return the value expected by the consumer; an empty replacement can disable the
built-in operation. The shipped templates use the internal bridge registry and
can serve as references for those arguments.

## Tests

```sh
python -m pip install -r tests/requirements.txt
python -m unittest discover -s tests -p 'test_*.py' -v
```

The suite loads the real Lua provider and engine files through Lua 5.4 and supplies
controlled framework, export and native boundaries. It covers every provider's
documented method surface plus the framework, inventory, zone, callback and
initialization behavior above. GitHub Actions runs it on Python 3.11 and 3.13.
Real FiveM replication and proprietary external integrations require in-game
validation.
