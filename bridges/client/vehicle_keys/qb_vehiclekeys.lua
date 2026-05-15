local provider = LyreBridge.registerProvider("client", "vehicle_keys", "qb_vehiclekeys", 20)

---Active when the `qb-vehiclekeys` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-vehiclekeys")
end

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    TriggerEvent("vehiclekeys:client:SetOwner", plate)
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    TriggerServerEvent("qb-vehiclekeys:server:AcquireVehicleKeys", plate)
end
