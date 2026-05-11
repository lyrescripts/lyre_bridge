local provider = LyreBridge.registerProvider("client", "fuel", "native", 1000)

function provider:detect()
    return true
end

function provider:set(vehicle, fuel)
    SetVehicleFuelLevel(vehicle, fuel)
end

function provider:get(vehicle)
    return GetVehicleFuelLevel(vehicle)
end
