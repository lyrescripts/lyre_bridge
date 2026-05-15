local provider = LyreBridge.registerProvider("client", "vehicle_keys", "ti_vehicle_keys", 120)

---Active when the `ti_vehicle_keys` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("ti_vehicle_keys")
end

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    exports.ti_vehicle_keys:GiveKey(plate)
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    exports.ti_vehicle_keys:RemoveKey(plate)
end
