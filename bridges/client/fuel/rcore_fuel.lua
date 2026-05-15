local provider = LyreBridge.registerProvider("client", "fuel", "rcore_fuel", 140)

---Active when the `rcore_fuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("rcore_fuel")
end

---Set the fuel level (0-100).
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    exports.rcore_fuel:SetFuel(vehicle, fuel)
end

---Current fuel level (0-100).
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return exports.rcore_fuel:GetFuel(vehicle)
end
