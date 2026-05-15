local provider = LyreBridge.registerProvider("client", "fuel", "cdn_fuel", 110)

---Active when the `cdn-fuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("cdn-fuel")
end

---Set the fuel level (0-100).
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    exports["cdn-fuel"]:SetFuel(vehicle, fuel)
end

---Current fuel level (0-100).
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return exports["cdn-fuel"]:GetFuel(vehicle)
end
