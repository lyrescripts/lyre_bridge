local provider = LyreBridge.registerProvider("client", "fuel", "lyre_fuel", 10)

function provider:detect()
    return bridge.core.isStarted("lyre_fuel")
end

function provider:set(vehicle, fuel)
    exports.lyre_fuel:SetFuel(vehicle, fuel)
end

function provider:get(vehicle)
    return exports.lyre_fuel:GetFuel(vehicle)
end
