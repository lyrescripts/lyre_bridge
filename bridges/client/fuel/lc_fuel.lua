local provider = LyreBridge.registerProvider("client", "fuel", "lc_fuel", 130)

function provider:detect()
    return bridge.core:isStarted("lc_fuel")
end

function provider:set(vehicle, fuel)
    exports.lc_fuel:SetFuel(vehicle, fuel)
end

function provider:get(vehicle)
    return exports.lc_fuel:GetFuel(vehicle)
end
