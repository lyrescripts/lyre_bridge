LyreBridge.registerProvider("server", "dispatch", {
    name = "0r-dispatch",
    resource = "0r-dispatch",
    priority = 100,
    send = function(self, context)
        local payload = context.payload

        exports["0r-dispatch"]:SendAlert(
            payload.source,
            payload.title,
            payload.code,
            payload.icon,
            payload.jobs,
            payload.blip.sprite
        )

        return true, true
    end,
})
