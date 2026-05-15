local provider = LyreBridge.registerProvider("client", "fuel", "qb_fuel", 90)

---Active when the `qb-fuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-fuel")
end

---Set the fuel level (0-100).
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    exports["qb-fuel"]:SetFuel(vehicle, fuel)
end

---Current fuel level (0-100).
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return exports["qb-fuel"]:GetFuel(vehicle)
end
