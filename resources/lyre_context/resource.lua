LyreBridge.registerResource("lyre_context", {
    path = "resources/lyre_context",
    bridge = {
        locked = false,
        client = {
            "bridge/client/cl_esx.lua",
            "bridge/client/cl_example.lua",
            "bridge/client/cl_qbcore.lua",
        },
        server = {
        },
    },
    sql = {
        locked = false,
        files = {
        },
        frameworkFiles = {
        },
    },
})

