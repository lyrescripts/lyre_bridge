local provider = LyreBridge.registerProvider("client", "dispatch", "ps_dispatch", 30)

function provider:detect()
    return bridge.core.isStarted("ps-dispatch")
end

function provider:send(payload)
    exports["ps-dispatch"]:CustomAlert({
        coords = payload.coords or GetEntityCoords(PlayerPedId()),
        message = payload.message or payload.description or "Alert",
        dispatchCode = payload.code or "10-30",
        description = payload.description or payload.message,
        radius = payload.radius or 0,
        sprite = (payload.blip and payload.blip.sprite) or 161,
        color = (payload.blip and payload.blip.color) or 1,
        scale = (payload.blip and payload.blip.scale) or 1.5,
        length = (payload.blip and payload.blip.duration) or 60,
        sound = payload.sound,
        sound2 = payload.sound2,
        offset = payload.offset,
        blip = (payload.blip and payload.blip.show) ~= false,
        jobs = payload.jobs or { "leo" },
    })
end
