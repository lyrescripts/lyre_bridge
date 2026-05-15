local provider = LyreBridge.registerProvider("client", "fuel", "lyre_fuel", 10)

---Active when the `lyre_fuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("lyre_fuel")
end

---Set the fuel level (0-100).
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    exports.lyre_fuel:SetFuel(vehicle, fuel)
end

---Current fuel level (0-100).
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return exports.lyre_fuel:GetFuel(vehicle)
end
