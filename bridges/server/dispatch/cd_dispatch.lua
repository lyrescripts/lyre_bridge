local provider = LyreBridge.registerProvider("server", "dispatch", "cd_dispatch", 50)

---Active when the `cd_dispatch` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("cd_dispatch")
end

---Forward a dispatch alert to cd_dispatch.
---@param payload BridgeDispatchPayload
function provider:send(payload)
    exports["cd_dispatch"]:AddCustomNotification({
        job_table = payload.jobs or { "police" },
        coords = payload.coords,
        title = payload.title or "Dispatch",
        message = payload.message or payload.description or "Alert",
        flash = payload.flash or 0,
        unique_id = tostring(math.random(1, 1000000)),
        sound = payload.sound or 1,
        blip = payload.blip,
    })
end
