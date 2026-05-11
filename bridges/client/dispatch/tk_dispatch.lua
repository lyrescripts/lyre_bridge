local provider = LyreBridge.registerProvider("client", "dispatch", "tk_dispatch", 60)

function provider:detect()
    return bridge.core:isStarted("tk_dispatch")
end

function provider:send(payload)
    exports.tk_dispatch:sendAlert({
        coords = payload.coords or GetEntityCoords(PlayerPedId()),
        jobs = payload.jobs or { "police" },
        title = payload.title or "Dispatch",
        description = payload.description or payload.message or "Alert",
        blip = payload.blip,
    })
end
