fx_version("cerulean")
game("gta5")

author("Lyre Scripts")
description("Shared modular bridge core, lazy compatibility modules, and automatic SQL migrations for Lyre resources.")
version("1.1.0")
lua54("yes")

escrow_ignore({
    "README.md",
    "config.lua",
    "imports/**/*.lua",
    "custom/**/*.lua",
    "examples/**/*.lua",
    "resources/**/*.lua",
    "resources/**/*.sql",
    "schemas/**/*.lua",
})

shared_scripts({
    "config.lua",
    "imports/shared.lua",
})

server_scripts({
    "@oxmysql/lib/MySQL.lua",
    "imports/server.lua",
    "schemas/*.lua",
    "resources/**/resource.lua",
    "server/sql/core.lua",
    "server/sql/schema.lua",
    "server/sql/migrations.lua",
    "server/sql/statements.lua",
    "server/sql/resources.lua",
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
    "imports/**/*.lua",
    "resources/**/*.lua",
    "resources/**/*.sql",
})

server_exports({
    "CheckResourceDefinitions",
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
