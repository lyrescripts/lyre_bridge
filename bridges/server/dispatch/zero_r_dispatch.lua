local provider = LyreBridge.registerProvider("server", "dispatch", "zero_r_dispatch", 10)

---Active when the `0r_dispatch` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("0r_dispatch")
end

---Forward a dispatch alert to 0r_dispatch.
---@param payload BridgeDispatchPayload
function provider:send(payload)
    exports["0r_dispatch"]:CreateDispatchCall({
        jobs = payload.jobs or { "police" },
        coords = payload.coords,
        title = payload.title or "Dispatch",
        message = payload.message or payload.description or "Alert",
        blip = payload.blip,
    })
end
