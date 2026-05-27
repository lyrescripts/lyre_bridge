local provider = LyreBridge.registerProvider("client", "dispatch", "cd_dispatch3d", 9)

---@return boolean
function provider:detect()
    return bridge.core.isStarted("cd_dispatch3d")
end

---@param payload BridgeDispatchPayload
function provider:send(payload)
    local data = exports["cd_dispatch3d"]:GetPlayerInfo()
    local coords = payload.coords or data.coords
    TriggerServerEvent("cd_dispatch:AddNotification", {
        job_table = payload.jobs or { "police" },
        coords = coords,
        title = payload.title or "Dispatch",
        message = payload.message or payload.description or "Alert",
        flash = payload.flash or 0,
        unique_id = data.unique_id or tostring(math.random(1, 1000000)),
        sound = payload.sound or 1,
        blip = {
            sprite = (payload.blip and payload.blip.sprite) or 161,
            scale = (payload.blip and payload.blip.scale) or 1.2,
            colour = (payload.blip and payload.blip.color) or 1,
            flashes = (payload.blip and payload.blip.flashes) or false,
            text = (payload.blip and payload.blip.label) or payload.title or "Dispatch",
            time = (payload.blip and payload.blip.duration) or 5,
            radius = (payload.blip and payload.blip.radius) or 0,
        },
    })
end
