LyreBridge.registerResource("lyre_illegalmissions-murderer", {
    path = "resources/lyre_illegalmissions-murderer",
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

