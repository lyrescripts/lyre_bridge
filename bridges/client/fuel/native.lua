local provider = LyreBridge.registerProvider("client", "fuel", "native", 1000)

---Always active; the native fuel level is the universal fallback.
---@return boolean
function provider:detect()
    return true
end

---Set the fuel level (0-100) via the native state.
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    SetVehicleFuelLevel(vehicle, fuel)
end

---Current fuel level (0-100) from the native state.
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return GetVehicleFuelLevel(vehicle)
end
