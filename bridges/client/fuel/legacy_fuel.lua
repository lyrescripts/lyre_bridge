local provider = LyreBridge.registerProvider("client", "fuel", "legacy_fuel", 50)

---Active when the `LegacyFuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("LegacyFuel")
end

---Set the fuel level (0-100).
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    exports.LegacyFuel:SetFuel(vehicle, fuel)
end

---Current fuel level (0-100).
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return exports.LegacyFuel:GetFuel(vehicle)
end
