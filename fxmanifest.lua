fx_version("cerulean")
game("gta5")

author("Lyre Scripts")
description("Shared modular bridge core, lazy compatibility modules, and automatic SQL migrations for Lyre resources.")
version("1.0.2")
lua54("yes")

escrow_ignore({
    "README.md",
    "config.lua",
    "imports/**/*.lua",
    "custom/**/*.lua",
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
    "resources/lyre_boatschool/resource.lua",
    "resources/lyre_carrental/resource.lua",
    "resources/lyre_carwash/resource.lua",
    "resources/lyre_context-defaults/resource.lua",
    "resources/lyre_context/resource.lua",
    "resources/lyre_deathscreen/resource.lua",
    "resources/lyre_drivingschool/resource.lua",
    "resources/lyre_flightschool/resource.lua",
    "resources/lyre_fuel/resource.lua",
    "resources/lyre_garage/resource.lua",
    "resources/lyre_hunting/resource.lua",
    "resources/lyre_illegalmissions-atm/resource.lua",
    "resources/lyre_illegalmissions-cartheft/resource.lua",
    "resources/lyre_illegalmissions-gofast/resource.lua",
    "resources/lyre_illegalmissions-moneytruck/resource.lua",
    "resources/lyre_illegalmissions-murderer/resource.lua",
    "resources/lyre_illegalmissions/resource.lua",
    "resources/lyre_template/resource.lua",
    "resources/lyre_tennis/resource.lua",
    "resources/ox_target/resource.lua",
    "resources/qb-target/resource.lua",
    "resources/qtarget/resource.lua",
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
