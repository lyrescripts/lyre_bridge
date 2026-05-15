local provider = LyreBridge.registerProvider("client", "vehicle_keys", "tgiann_hotwire", 100)

---Active when the `tgiann-hotwire` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("tgiann-hotwire")
end

---Grant the local player keys for `plate`.
---@param vehicle integer
---@param plate string
function provider:give(vehicle, plate)
    exports["tgiann-hotwire"]:GiveKey(plate)
end

---Revoke the local player's keys for `plate`.
---@param plate string
function provider:remove(plate)
    exports["tgiann-hotwire"]:RemoveKey(plate)
end
