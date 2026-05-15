local provider = LyreBridge.registerProvider("client", "dispatch", "core_dispatch", 50)

---Active when the `core_dispatch` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("core_dispatch")
end

---Forward a dispatch alert to core_dispatch.
---@param payload BridgeDispatchPayload
function provider:send(payload)
    local coords = payload.coords or GetEntityCoords(PlayerPedId())
    TriggerServerEvent("core_dispatch:addCall",
        payload.code or "10-30",
        payload.title or "Dispatch",
        { { icon = "fa-info-circle", info = payload.message or payload.description or "Alert" } },
        { coords.x, coords.y, coords.z },
        "police",
        (payload.blip and payload.blip.duration) or 60,
        (payload.blip and payload.blip.sprite) or 161,
        (payload.blip and payload.blip.color) or 1
    )
end
