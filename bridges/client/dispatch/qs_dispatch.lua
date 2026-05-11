local provider = LyreBridge.registerProvider("client", "dispatch", "qs_dispatch", 20)

function provider:detect()
    return bridge.core:isStarted("qs-dispatch")
end

function provider:send(payload)
    exports["qs-dispatch"]:getDispatchAlert({
        job = payload.jobs or { "police" },
        coords = payload.coords or GetEntityCoords(PlayerPedId()),
        message = payload.message or payload.description or "Alert",
        code = payload.code or "10-30",
        title = payload.title or "Dispatch",
        gender = payload.gender,
        firstStreet = payload.firstStreet,
        secondStreet = payload.secondStreet,
        sprite = (payload.blip and payload.blip.sprite) or 161,
        color = (payload.blip and payload.blip.color) or 1,
        scale = (payload.blip and payload.blip.scale) or 1.5,
        length = (payload.blip and payload.blip.duration) or 60,
    })
end
