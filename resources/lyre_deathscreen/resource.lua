LyreBridge.registerResource("lyre_deathscreen", {
    path = "resources/lyre_deathscreen",
    bridge = {
        client = {
            "bridge/client/esx.lua",
            "bridge/client/example.lua",
            "bridge/client/qbcore.lua",
            "bridge/client/qbox.lua",
            "bridge/client/standalone.lua",
        },
        server = {
            "bridge/server/esx.lua",
            "bridge/server/example.lua",
            "bridge/server/qbcore.lua",
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

