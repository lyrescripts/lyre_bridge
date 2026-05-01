LyreBridge.registerResource("lyre_fuel", {
    path = "resources/lyre_fuel",
    bridge = {
        locked = false,
        client = {
            "bridge/client/cl_esx.lua",
            "bridge/client/cl_example.lua",
            "bridge/client/cl_qbcore.lua",
        },
        server = {
            "bridge/server/sv_esx.lua",
            "bridge/server/sv_example.lua",
            "bridge/server/sv_qbcore.lua",
        },
    },
    sql = {
        locked = false,
        files = {
            { id = "import_sql", path = "sql/import.sql", required = true, order = 10 },
        },
        frameworkFiles = {
            ESX = {
                { id = "inventory_items_esx", path = "sql/inventory_items/esx.sql", required = false, order = 100, requiresTables = { "items" } },
            },
        },
    },
})

