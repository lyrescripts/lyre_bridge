LyreBridge.registerResource("lyre_template", {
    path = "resources/lyre_template",
    bridge = {
        client = {
            "bridge/client/example.lua",
            "bridge/client/qbox.lua",
        },
        server = {
            "bridge/server/example.lua",
            "bridge/server/qbox.lua",
        },
    },
    sql = {
        files = {
        },
        frameworkFiles = {
        },
    },
})

