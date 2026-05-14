local provider = LyreBridge.registerProvider("server", "dispatch", "ps_dispatch", 40)

function provider:detect()
    return bridge.core.isStarted("ps-dispatch")
end

function provider:send(payload)
    exports["ps-dispatch"]:CustomServerAlert({
        coords = payload.coords,
        dispatchCode = payload.code or "10-30",
        message = payload.message or payload.description or "Alert",
        description = payload.description or payload.message,
        jobs = payload.jobs or { "leo" },
    })
end
