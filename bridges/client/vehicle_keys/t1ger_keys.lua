local provider = LyreBridge.registerProvider("client", "vehicle_keys", "t1ger_keys", 90)

---Active when the `t1ger_keys` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("t1ger_keys")
end

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    TriggerServerEvent("t1ger_keys:server:GiveKey", plate)
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    TriggerServerEvent("t1ger_keys:server:RemoveKey", plate)
end
