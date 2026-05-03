LyreBridge.registerProvider("server", "dispatch", {
    name = "ps-dispatch",
    resource = "ps-dispatch",
    priority = 125,
    send = function(self, context)
        local payload = context.payload

        TriggerEvent("ps-dispatch:server:notify", {
            message = payload.title,
            codeName = payload.codeName or payload.code or "dispatch",
            code = payload.code,
            icon = payload.icon,
            priority = payload.priority,
            coords = payload.coords,
            description = payload.description or payload.message,
            jobs = payload.jobs,
            radius = payload.blip and payload.blip.radius or 0,
            sprite = payload.blip and payload.blip.sprite,
            color = payload.blip and payload.blip.color,
            scale = payload.blip and payload.blip.scale,
            length = payload.blip and math.max(1, math.ceil((payload.blip.duration or 60000) / 60000)) or nil,
            sound = payload.sound,
        })

        return true, true
    end,
})
