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
