LyreBridge.registerResource("lyre_illegalmissions-cartheft", {
    path = "resources/lyre_illegalmissions-cartheft",
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

