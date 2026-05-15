local provider = LyreBridge.registerProvider("client", "dispatch", "tk_dispatch", 60)

---Active when the `tk_dispatch` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("tk_dispatch")
end

---Forward a dispatch alert to tk_dispatch.
---@param payload BridgeDispatchPayload
function provider:send(payload)
    exports.tk_dispatch:sendAlert({
        coords = payload.coords or GetEntityCoords(PlayerPedId()),
        jobs = payload.jobs or { "police" },
        title = payload.title or "Dispatch",
        description = payload.description or payload.message or "Alert",
        blip = payload.blip,
    })
end
