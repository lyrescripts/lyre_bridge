local provider = LyreBridge.registerProvider("client", "fuel", "qb_fuel", 90)

function provider:detect()
    return bridge.core:isStarted("qb-fuel")
end

function provider:set(vehicle, fuel)
    exports["qb-fuel"]:SetFuel(vehicle, fuel)
end

function provider:get(vehicle)
    return exports["qb-fuel"]:GetFuel(vehicle)
end
