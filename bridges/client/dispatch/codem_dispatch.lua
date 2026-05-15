local provider = LyreBridge.registerProvider("client", "dispatch", "codem_dispatch", 70)

---Active when the `codem-dispatch` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("codem-dispatch")
end

---Forward a dispatch alert to codem-dispatch.
---@param payload BridgeDispatchPayload
function provider:send(payload)
    exports["codem-dispatch"]:CustomDispatch({
        coords = payload.coords or GetEntityCoords(PlayerPedId()),
        jobs = payload.jobs or { "police" },
        title = payload.title or "Dispatch",
        message = payload.message or payload.description or "Alert",
        code = payload.code or "10-30",
        blip = payload.blip,
    })
end
