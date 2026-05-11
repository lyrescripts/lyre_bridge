local provider = LyreBridge.registerProvider("client", "fuel", "ox_fuel", 20)

function provider:detect()
    return bridge.core:isStarted("ox_fuel")
end

function provider:set(vehicle, fuel)
    Entity(vehicle).state.fuel = fuel
end

function provider:get(vehicle)
    return Entity(vehicle).state.fuel or GetVehicleFuelLevel(vehicle)
end
