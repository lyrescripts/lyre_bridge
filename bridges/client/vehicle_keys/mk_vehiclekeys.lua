local provider = LyreBridge.registerProvider("client", "vehicle_keys", "mk_vehiclekeys", 70)

---Active when the `mk_vehiclekeys` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("mk_vehiclekeys")
end

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    exports.mk_vehiclekeys:AddKey(vehicle)
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    exports.mk_vehiclekeys:RemoveKey(plate)
end
