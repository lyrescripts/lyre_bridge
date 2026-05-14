local provider = LyreBridge.registerProvider("client", "fuel", "renewed_fuel", 30)

function provider:detect()
    return bridge.core.isStarted("Renewed-Fuel")
end

function provider:set(vehicle, fuel)
    Entity(vehicle).state.fuel = fuel
end

function provider:get(vehicle)
    return Entity(vehicle).state.fuel or GetVehicleFuelLevel(vehicle)
end
