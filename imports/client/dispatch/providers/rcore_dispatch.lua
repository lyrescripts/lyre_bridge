LyreBridge.registerProvider("client", "dispatch", {
    name = "rcore_dispatch",
    resource = "rcore_dispatch",
    priority = 130,
    send = function(self, context)
        local payload = context.payload

        TriggerServerEvent("rcore_dispatch:server:sendAlert", {
            code = payload.code,
            default_priority = payload.priority == 1 and "high" or "medium",
            coords = payload.coords,
            job = payload.jobs,
            text = payload.message,
            type = payload.dispatchType or "medical",
            blip_time = math.max(1, math.ceil(payload.blip.duration / 1000)),
            blip = {
                sprite = payload.blip.sprite,
                colour = payload.blip.color,
                scale = payload.blip.scale,
                text = payload.blip.label,
                flashes = false,
                radius = 0,
            },
        })

        return true, true
    end,
})
