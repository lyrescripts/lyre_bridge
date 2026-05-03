LyreBridge.registerResource("lyre_garage", {
    path = "resources/lyre_garage",
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
        },
        frameworkFiles = {
            ESX = {
                { id = "import_esx", path = "sql/import_esx.sql", required = true, order = 10 },
            },
            QBCORE = {
                { id = "import_qb", path = "sql/import_qb.sql", required = true, order = 10 },
            },
            QBOX = {
                { id = "import_qb", path = "sql/import_qb.sql", required = true, order = 10 },
            },
        },
    },
})

