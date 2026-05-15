local provider = LyreBridge.registerProvider("client", "vehicle_keys", "mrnewb_vehiclekeys", 50)

---Active when the `MrNewbVehicleKeys` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("MrNewbVehicleKeys")
end

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    exports.MrNewbVehicleKeys:GiveKeys(vehicle)
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    exports.MrNewbVehicleKeys:RemoveKeys(plate)
end
