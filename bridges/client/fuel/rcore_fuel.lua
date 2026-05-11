local provider = LyreBridge.registerProvider("client", "fuel", "rcore_fuel", 140)

function provider:detect()
    return bridge.core:isStarted("rcore_fuel")
end

function provider:set(vehicle, fuel)
    exports.rcore_fuel:SetFuel(vehicle, fuel)
end

function provider:get(vehicle)
    return exports.rcore_fuel:GetFuel(vehicle)
end
