local provider = LyreBridge.registerProvider("client", "vehicle_keys", "wasabi_carlock", 40)

---Active when the `wasabi_carlock` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("wasabi_carlock")
end

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    exports.wasabi_carlock:GiveKey(plate)
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    exports.wasabi_carlock:RemoveKey(plate)
end
