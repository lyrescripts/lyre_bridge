fx_version("cerulean")
game("gta5")

author("Lyre Scripts")
description("Provider-based compatibility bridge for the Lyre resource pack.")
version("2.2.0")
lua54("yes")

escrow_ignore({
    "README.md",
    "config.lua",
    "imports.lua",
    "engine/**/*.lua",
    "utils/**/*.lua",
    "bridges/**/*.lua",
    "resources/**/*.lua",
})

shared_scripts({
    "config.lua",

    "engine/registry.lua",
    "engine/resolver.lua",
    "engine/bridge.lua",
    "engine/configuration.lua",
    "engine/custom.lua",

    "utils/log.lua",
    "utils/isStarted.lua",
    "utils/setDebug.lua",
})

client_scripts({
    "engine/client_relay.lua",
    "bridges/client/**/*.lua",
})

server_scripts({
    "@oxmysql/lib/MySQL.lua",
    "engine/version_check.lua",
    "bridges/server/**/*.lua",
})

files({
    "imports.lua",
    "resources/**/*.lua",
})

dependencies({
    "oxmysql",
})
