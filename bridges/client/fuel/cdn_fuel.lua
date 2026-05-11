local provider = LyreBridge.registerProvider("client", "fuel", "cdn_fuel", 110)

function provider:detect()
    return bridge.core:isStarted("cdn-fuel")
end

function provider:set(vehicle, fuel)
    exports["cdn-fuel"]:SetFuel(vehicle, fuel)
end

function provider:get(vehicle)
    return exports["cdn-fuel"]:GetFuel(vehicle)
end
