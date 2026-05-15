local provider = LyreBridge.registerProvider("client", "fuel", "ox_fuel", 20)

---Active when the `ox_fuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("ox_fuel")
end

---Set the fuel level (0-100) via the entity state bag.
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    Entity(vehicle).state.fuel = fuel
end

---Current fuel level (0-100); falls back to the native value when no state is set.
---@param vehicle integer
---@return number
function provider:get(vehicle)
    return Entity(vehicle).state.fuel or GetVehicleFuelLevel(vehicle)
end
