fx_version("cerulean")
game("gta5")

author("Lyre Scripts")
description("Shared modular bridge core, lazy compatibility modules, and automatic SQL migrations for Lyre resources.")
version("1.0.0")
lua54("yes")

escrow_ignore({
    "README.md",
    "custom/**/*.lua",
    "resources/**/*.lua",
    "resources/**/*.sql",
    "schemas/**/*.lua",
})

shared_scripts({
    "imports/shared.lua",
})

server_scripts({
    "@oxmysql/lib/MySQL.lua",
    "imports/server.lua",
    "schemas/*.lua",
    "resources/*/resource.lua",
    "server/sql.lua",
    "server/main.lua",
    "custom/server/*.lua",
})

client_scripts({
    "imports/client.lua",
    "client/*.lua",
    "custom/client/*.lua",
})

files({
    "resources/**/*.sql",
})

server_exports({
    "EnsureResourceSchema",
    "GetResourceDefinition",
    "ListRegisteredResources",
    "SqlQuery",
    "SqlSingle",
    "SqlScalar",
    "SqlUpdate",
    "SqlInsert",
    "SqlTransaction",
    "SqlReady",
})

exports({
    "BridgeVersion",
})

dependencies({
    "oxmysql",
})
