local provider = LyreBridge.registerProvider("client", "vehicle_keys", "fivecode_carkeys", 80)

---Active when the `5code_carkeys` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("5code_carkeys")
end

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    exports["5code_carkeys"]:AddKey(plate)
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    exports["5code_carkeys"]:RemoveKey(plate)
end
