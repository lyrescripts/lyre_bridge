local provider = LyreBridge.registerProvider("client", "fuel", "lc_fuel", 130)

---Active when the `lc_fuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("lc_fuel")
end

---Set the fuel level (0-100).
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    exports.lc_fuel:SetFuel(vehicle, fuel)
end

---Current fuel level (0-100).
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return exports.lc_fuel:GetFuel(vehicle)
end
