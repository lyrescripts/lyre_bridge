LyreBridge.registerResource("lyre_template", {
    path = "resources/lyre_template",
    bridge = {
        locked = false,
        client = {
            "bridge/client/example.lua",
        },
        server = {
            "bridge/server/example.lua",
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

