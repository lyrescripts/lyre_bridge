local DECOR = "_FUEL_LEVEL"

local provider = LyreBridge.registerProvider("client", "fuel", "frfuel", 160)

function provider:detect()
    return bridge.core:isStarted("FRFuel")
end

function provider:set(vehicle, fuel)
    SetVehicleFuelLevel(vehicle, fuel)
    DecorSetFloat(vehicle, DECOR, fuel)
end

function provider:get(vehicle)
    if DecorExistOn(vehicle, DECOR) then
        return DecorGetFloat(vehicle, DECOR)
    end
    return GetVehicleFuelLevel(vehicle)
end
