local provider = LyreBridge.registerProvider("server", "dispatch", "lb_tablet", 60)

function provider:detect()
    return bridge.core:isStarted("lb-tablet")
end

function provider:send(payload)
    exports["lb-tablet"]:AddCall({
        title = payload.title or "Dispatch",
        description = payload.description or payload.message or "Alert",
        coords = payload.coords,
        jobs = payload.jobs or { "police" },
        blip = payload.blip,
    })
end
