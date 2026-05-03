LyreBridge.registerProvider("client", "dispatch", {
    name = "cd_dispatch",
    resource = "cd_dispatch",
    priority = 100,
    send = function(self, context)
        local payload = context.payload
        local data = {}

        pcall(function()
            data = exports["cd_dispatch"]:GetPlayerInfo() or {}
        end)

        TriggerServerEvent("cd_dispatch:AddNotification", {
            job_table = payload.jobs,
            coords = data.coords or payload.coords,
            title = payload.code .. " - " .. payload.title,
            message = payload.message,
            flash = 0,
            unique_id = data.unique_id or tostring(math.random(1000000, 9999999)),
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
