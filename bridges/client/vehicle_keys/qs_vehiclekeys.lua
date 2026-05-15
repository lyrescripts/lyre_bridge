local provider = LyreBridge.registerProvider("client", "vehicle_keys", "qs_vehiclekeys", 30)

---Active when the `qs-vehiclekeys` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qs-vehiclekeys")
end

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    exports["qs-vehiclekeys"]:GiveKeys(plate)
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    exports["qs-vehiclekeys"]:RemoveKeys(plate)
end
