local provider = LyreBridge.registerProvider("client", "fuel", "ps_fuel", 60)

---Active when the `ps-fuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("ps-fuel")
end

---Set the fuel level (0-100).
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    exports["ps-fuel"]:SetFuel(vehicle, fuel)
end

---Current fuel level (0-100).
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return exports["ps-fuel"]:GetFuel(vehicle)
end
