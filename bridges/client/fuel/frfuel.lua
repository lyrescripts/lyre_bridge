local DECOR = "_FUEL_LEVEL"

local provider = LyreBridge.registerProvider("client", "fuel", "frfuel", 160)

---Active when the `FRFuel` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("FRFuel")
end

---Set the fuel level (0-100); mirrored into the FRFuel decor.
---@param vehicle integer
---@param fuel number
function provider:set(vehicle, fuel)
    SetVehicleFuelLevel(vehicle, fuel)
    DecorSetFloat(vehicle, DECOR, fuel)
end

---Current fuel level (0-100); falls back to the native value when the decor is missing.
---@param vehicle integer
---@return number
function provider:get(vehicle)
    if DecorExistOn(vehicle, DECOR) then
        return DecorGetFloat(vehicle, DECOR)
    end
    return GetVehicleFuelLevel(vehicle)
end
