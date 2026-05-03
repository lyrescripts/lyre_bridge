LyreBridge.registerResource("lyre_template", {
    path = "resources/lyre_template",
    bridge = {
        client = {
            "bridge/client/esx.lua",
            "bridge/client/qbcore.lua",
            "bridge/client/example.lua",
            "bridge/client/qbox.lua",
            "bridge/client/standalone.lua",
        },
        server = {
            "bridge/server/esx.lua",
            "bridge/server/qbcore.lua",
            "bridge/server/example.lua",
            "bridge/server/qbox.lua",
            "bridge/server/standalone.lua",
        },
    },
    sql = {
        files = {
        },
        frameworkFiles = {
        },
    },
})

