local provider = LyreBridge.registerProvider("client", "vehicle_keys", "qbx_vehiclekeys", 10)

---Active when the `qbx_vehiclekeys` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qbx_vehiclekeys")
end

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    TriggerServerEvent("__ox_cb_qbx_vehiclekeys:server:giveKeys", GetCurrentResourceName(), "dummy", VehToNet(vehicle))
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    TriggerServerEvent("qbx_vehiclekeys:server:removeKeys", plate)
end
