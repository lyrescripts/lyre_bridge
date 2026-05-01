LyreBridge.registerResource("lyre_context-defaults", {
    path = "resources/lyre_context-defaults",
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
        },
        frameworkFiles = {
        },
    },
})

