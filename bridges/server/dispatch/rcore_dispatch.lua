local provider = LyreBridge.registerProvider("server", "dispatch", "rcore_dispatch", 30)

---Active when the `rcore_dispatch` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("rcore_dispatch")
end

---Forward a dispatch alert to rcore_dispatch.
---@param payload BridgeDispatchPayload
function provider:send(payload)
    exports.rcore_dispatch:sendServerAlert({
        jobs = payload.jobs or { "police" },
        coords = payload.coords,
        title = payload.title or "Dispatch",
        description = payload.description or payload.message or "Alert",
        blip = payload.blip,
    })
end
