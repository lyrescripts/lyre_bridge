local provider = LyreBridge.registerProvider("client", "fuel", "bigdaddy_fuel", 120)

function provider:detect()
    return bridge.core:isStarted("BigDaddy-Fuel")
end

function provider:set(vehicle, fuel)
    exports["BigDaddy-Fuel"]:SetFuel(vehicle, fuel)
end

function provider:get(vehicle)
    return exports["BigDaddy-Fuel"]:GetFuel(vehicle)
end
