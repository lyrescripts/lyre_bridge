local provider = LyreBridge.registerProvider("client", "dispatch", "rcore_dispatch", 40)

function provider:detect()
    return bridge.core.isStarted("rcore_dispatch")
end

function provider:send(payload)
    exports.rcore_dispatch:sendAlert({
        job = payload.jobs or { "police" },
        coords = payload.coords or GetEntityCoords(PlayerPedId()),
        title = payload.title or "Dispatch",
        description = payload.description or payload.message or "Alert",
        blip = payload.blip,
    })
end
