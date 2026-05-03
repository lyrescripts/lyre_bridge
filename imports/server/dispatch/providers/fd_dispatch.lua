LyreBridge.registerProvider("server", "dispatch", {
    name = "fd_dispatch",
    resource = "fd_dispatch",
    priority = 110,
    send = function(self, context)
        local payload = context.payload

        exports.fd_dispatch:addAlert({
            source = payload.source,
            code = payload.code,
            title = payload.title,
            description = payload.message,
            message = payload.message,
            coords = payload.coords,
            jobs = payload.jobs,
            priority = payload.priority,
            blip = {
                sprite = payload.blip.sprite,
                color = payload.blip.color,
                scale = payload.blip.scale,
                label = payload.blip.label,
                duration = payload.blip.duration,
            },
        })

        return true, true
    end,
})
