local DECOR = "_ANDY_FUEL_DECORE_"

local provider = LyreBridge.registerProvider("client", "fuel", "nd_fuel", 40)

function provider:detect()
    return bridge.core.isStarted("ND_Fuel")
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
