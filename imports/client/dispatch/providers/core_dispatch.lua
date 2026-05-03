LyreBridge.registerProvider("client", "dispatch", {
    name = "core_dispatch",
    resource = "core_dispatch",
    priority = 140,
    send = function(self, context)
        local payload = context.payload
        local coords = payload.coordsTable or payload.coords
        if not coords then
            return false
        end

        for _, jobName in ipairs(payload.jobs or {}) do
            TriggerServerEvent(
                "core_dispatch:addCall",
                payload.code,
                payload.title,
                { { icon = payload.icon, info = payload.message } },
                { coords.x, coords.y, coords.z },
                jobName,
                payload.blip.duration,
                payload.blip.sprite,
                payload.blip.color
            )
        end

        return true, true
    end,
})
