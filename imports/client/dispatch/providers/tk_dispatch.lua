LyreBridge.registerProvider("client", "dispatch", {
    name = "tk_dispatch",
    resource = "tk_dispatch",
    priority = 150,
    send = function(self, context)
        local payload = context.payload

        exports["tk_dispatch"]:addCall({
            title = payload.title,
            code = payload.code,
            priority = payload.priority == 1 and "high" or "medium",
            coords = payload.coords,
            message = payload.message,
            jobs = payload.jobs,
            showLocation = true,
            showDirection = true,
            blip = {
                sprite = payload.blip.sprite,
                color = payload.blip.color,
                scale = payload.blip.scale,
                label = payload.blip.label,
                time = payload.blip.duration,
            },
        })

        return true, true
    end,
})
