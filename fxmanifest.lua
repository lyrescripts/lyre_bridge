fx_version("cerulean")
game("gta5")

author("Lyre Scripts")
description("Provider-based compatibility bridge for the Lyre resource pack.")
version("2.0.0")
lua54("yes")

escrow_ignore({
    "README.md",
    "config.lua",
    "imports.lua",
    "engine/**/*.lua",
    "utils/**/*.lua",
    "bridges/**/*.lua",
    "bootstrap/**/*.lua",
    "resources/**/*.lua",
})

shared_scripts({
    "bootstrap/shared.lua",
})

client_scripts({
    "bootstrap/client.lua",
})

server_scripts({
    "@oxmysql/lib/MySQL.lua",
    "bootstrap/server.lua",
})

files({
    "imports.lua",
    "config.lua",
    "engine/**/*.lua",
    "utils/**/*.lua",
    "bridges/**/*.lua",
    "resources/**/*.lua",
})

dependencies({
    "oxmysql",
})
