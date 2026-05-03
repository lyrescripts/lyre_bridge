LyreBridge.registerProvider("server", "dispatch", {
    name = "cd_dispatch",
    resource = "cd_dispatch",
    priority = 130,
    send = function(self, context)
        local payload = context.payload

        TriggerClientEvent("cd_dispatch:AddNotification", -1, {
            job_table = payload.jobs,
            coords = payload.coords,
            title = payload.code .. " - " .. payload.title,
            message = payload.message,
            flash = 0,
            unique_id = tostring(math.random(1000000, 9999999)),
            sound = payload.sound,
            blip = {
                sprite = payload.blip.sprite,
                scale = payload.blip.scale,
                colour = payload.blip.color,
                flashes = false,
                text = payload.blip.label,
                time = math.max(1, math.ceil(payload.blip.duration / 60000)),
                radius = 0,
            },
        })

        return true, true
    end,
})
