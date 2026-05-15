local provider = LyreBridge.registerProvider("client", "fuel", "bigdaddy_fuel", 120)

---Active when the `BigDaddy-Fuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("BigDaddy-Fuel")
end

---Set the fuel level (0-100).
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    exports["BigDaddy-Fuel"]:SetFuel(vehicle, fuel)
end

---Current fuel level (0-100).
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return exports["BigDaddy-Fuel"]:GetFuel(vehicle)
end
