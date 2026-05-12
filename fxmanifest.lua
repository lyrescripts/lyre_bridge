fx_version("cerulean")
game("gta5")

author("Lyre Scripts")
description("Provider-based compatibility bridge for the Lyre resource pack.")
version("2.0.0")
lua54("yes")

escrow_ignore({
    "README.md",
    "config.lua",
    "engine/**/*.lua",
    "utils/**/*.lua",
    "bridges/**/*.lua",
    "imports/**/*.lua",
    "resources/**/*.lua",
    "old/**/*",
})

shared_scripts({
    "imports/shared.lua",
})

client_scripts({
    "imports/client.lua",
})

server_scripts({
    "@oxmysql/lib/MySQL.lua",
    "imports/server.lua",
})

files({
    "config.lua",
    "engine/**/*.lua",
    "utils/**/*.lua",
    "bridges/**/*.lua",
    "resources/**/*.lua",
})

dependencies({
    "oxmysql",
})
