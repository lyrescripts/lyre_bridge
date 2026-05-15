local provider = LyreBridge.registerProvider("server", "dispatch", "ps_dispatch", 40)

---Active when the `ps-dispatch` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("ps-dispatch")
end

---Forward a dispatch alert to ps-dispatch.
---@param payload BridgeDispatchPayload
function provider:send(payload)
    exports["ps-dispatch"]:CustomServerAlert({
        coords = payload.coords,
        dispatchCode = payload.code or "10-30",
        message = payload.message or payload.description or "Alert",
        description = payload.description or payload.message,
        jobs = payload.jobs or { "leo" },
    })
end
