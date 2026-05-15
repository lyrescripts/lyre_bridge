local provider = LyreBridge.registerProvider("server", "dispatch", "lb_tablet", 60)

---Active when the `lb-tablet` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("lb-tablet")
end

---Forward a dispatch alert to lb-tablet.
---@param payload BridgeDispatchPayload
function provider:send(payload)
    exports["lb-tablet"]:AddCall({
        title = payload.title or "Dispatch",
        description = payload.description or payload.message or "Alert",
        coords = payload.coords,
        jobs = payload.jobs or { "police" },
        blip = payload.blip,
    })
end
