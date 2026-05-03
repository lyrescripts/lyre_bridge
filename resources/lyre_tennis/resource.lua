LyreBridge.registerResource("lyre_tennis", {
    path = "resources/lyre_tennis",
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
        },
    },
})

