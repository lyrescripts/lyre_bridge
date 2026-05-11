fx_version("cerulean")
game("gta5")

author("Lyre Scripts")
description("Provider-based compatibility bridge for the Lyre resource pack.")
version("2.0.0")
lua54("yes")

escrow_ignore({
    "README.md",
    "engine/**/*.lua",
    "utils/**/*.lua",
    "bridges/**/*.lua",
    "resources/**/*.lua",
    "old/**/*",
})

shared_scripts({
    "engine/registry.lua",
    "engine/custom.lua",
    "engine/resolver.lua",
    "engine/bridge.lua",
    "utils/**/*.lua",
})

client_scripts({
    "bridges/client/**/*.lua",
})

server_scripts({
    "@oxmysql/lib/MySQL.lua",
    "bridges/server/**/*.lua",
})

files({
    "resources/**/*.lua",
})

dependencies({
    "oxmysql",
})
