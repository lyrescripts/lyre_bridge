local provider = LyreBridge.registerProvider("client", "fuel", "esx_sna_fuel", 80)

---Active when the `esx-sna-fuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("esx-sna-fuel")
end

---Set the fuel level (0-100).
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    exports["esx-sna-fuel"]:SetFuel(vehicle, fuel)
end

---Current fuel level (0-100).
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return exports["esx-sna-fuel"]:GetFuel(vehicle)
end
