local provider = LyreBridge.registerProvider("server", "dispatch", "fd_dispatch", 20)

function provider:detect()
    return bridge.core.isStarted("fd_dispatch")
end

function provider:send(payload)
    exports.fd_dispatch:CreateAlert({
        jobs = payload.jobs or { "police" },
        coords = payload.coords,
        title = payload.title or "Dispatch",
        description = payload.description or payload.message or "Alert",
        blip = payload.blip,
    })
end
