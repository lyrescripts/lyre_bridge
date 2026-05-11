local provider = LyreBridge.registerProvider("client", "fuel", "lj_fuel", 70)

function provider:detect()
    return bridge.core:isStarted("lj-fuel")
end

function provider:set(vehicle, fuel)
    exports["lj-fuel"]:SetFuel(vehicle, fuel)
end

function provider:get(vehicle)
    return exports["lj-fuel"]:GetFuel(vehicle)
end
