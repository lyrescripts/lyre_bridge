local provider = LyreBridge.registerProvider("client", "vehicle_keys", "renewed_vehiclekeys", 60)

---Active when the `Renewed-Vehiclekeys` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("Renewed-Vehiclekeys")
end

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    TriggerServerEvent("Renewed-Vehiclekeys:server:GiveKeys", plate)
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    TriggerServerEvent("Renewed-Vehiclekeys:server:RemoveKeys", plate)
end
