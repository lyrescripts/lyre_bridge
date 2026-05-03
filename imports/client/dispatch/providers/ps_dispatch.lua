LyreBridge.registerProvider("client", "dispatch", {
    name = "ps-dispatch",
    resource = "ps-dispatch",
    priority = 120,
    send = function(self, context)
        local payload = context.payload

        exports["ps-dispatch"]:CustomAlert({
            coords = payload.coords,
            message = payload.message,
            displayCode = payload.code,
            dispatchCode = payload.code,
            code = payload.code,
            description = payload.description,
            priority = payload.priority,
            recipientList = payload.jobs,
            jobs = payload.jobs,
            radius = 0,
            sprite = payload.blip.sprite,
            color = payload.blip.color,
            scale = payload.blip.scale,
            length = math.max(1, math.ceil(payload.blip.duration / 60000)),
            blipSprite = payload.blip.sprite,
            blipColour = payload.blip.color,
            blipScale = payload.blip.scale,
            blipLength = math.max(1, math.ceil(payload.blip.duration / 60000)),
            sound = payload.sound,
        })

        return true, true
    end,
})
