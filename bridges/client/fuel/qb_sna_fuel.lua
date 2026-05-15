local provider = LyreBridge.registerProvider("client", "fuel", "qb_sna_fuel", 100)

---Active when the `qb-sna-fuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-sna-fuel")
end

---Set the fuel level (0-100).
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    exports["qb-sna-fuel"]:SetFuel(vehicle, fuel)
end

---Current fuel level (0-100).
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return exports["qb-sna-fuel"]:GetFuel(vehicle)
end
