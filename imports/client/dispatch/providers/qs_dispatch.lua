LyreBridge.registerProvider("client", "dispatch", {
    name = "qs-dispatch",
    resource = "qs-dispatch",
    priority = 110,
    send = function(self, context)
        local payload = context.payload

        TriggerServerEvent("qs-dispatch:server:CreateDispatchCall", {
            job = payload.jobs,
            callLocation = payload.coords,
            callCode = { code = payload.code, snippet = payload.description },
            message = payload.message,
            flashes = false,
            blip = {
                sprite = payload.blip.sprite,
                scale = payload.blip.scale,
                colour = payload.blip.color,
                flashes = false,
                text = payload.blip.label,
                time = payload.blip.duration,
            },
            otherData = {
                { text = payload.playerName, icon = "fas fa-user-injured" },
            },
        })

        return true, true
    end,
})
