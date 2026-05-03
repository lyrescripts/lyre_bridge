LyreBridge.registerResource("lyre_illegalmissions-moneytruck", {
    path = "resources/lyre_illegalmissions-moneytruck",
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
        },
    },
})

