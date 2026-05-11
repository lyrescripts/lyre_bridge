local provider = LyreBridge.registerProvider("client", "fuel", "ps_fuel", 60)

function provider:detect()
    return bridge.core:isStarted("ps-fuel")
end

function provider:set(vehicle, fuel)
    exports["ps-fuel"]:SetFuel(vehicle, fuel)
end

function provider:get(vehicle)
    return exports["ps-fuel"]:GetFuel(vehicle)
end
