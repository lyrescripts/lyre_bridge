local provider = LyreBridge.registerProvider("client", "fuel", "ti_fuel", 150)

---Active when the `ti_fuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("ti_fuel")
end

---Set the fuel level (0-100); ti_fuel requires a fuel-type tag (`RON91`).
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    exports.ti_fuel:setFuel(vehicle, fuel, "RON91")
end

---Current fuel level (0-100).
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return exports.ti_fuel:getFuel(vehicle)
end
