local provider = LyreBridge.registerProvider("client", "fuel", "lj_fuel", 70)

---Active when the `lj-fuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("lj-fuel")
end

---Set the fuel level (0-100).
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    exports["lj-fuel"]:SetFuel(vehicle, fuel)
end

---Current fuel level (0-100).
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return exports["lj-fuel"]:GetFuel(vehicle)
end
