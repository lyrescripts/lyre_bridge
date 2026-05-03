LyreBridge.registerResource("lyre_hunting", {
    path = "resources/lyre_hunting",
    bridge = {
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

