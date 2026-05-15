local provider = LyreBridge.registerProvider("client", "vehicle_keys", "f_real_car_keys_system", 110)

---Active when the `f-realCarKeysSystem` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("f-realCarKeysSystem")
end

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    exports["f-realCarKeysSystem"]:GiveKeys(plate)
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    exports["f-realCarKeysSystem"]:RemoveKeys(plate)
end
