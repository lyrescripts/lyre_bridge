local provider = LyreBridge.registerProvider("client", "fuel", "legacy_fuel", 50)

function provider:detect()
    return bridge.core:isStarted("LegacyFuel")
end

function provider:set(vehicle, fuel)
    exports.LegacyFuel:SetFuel(vehicle, fuel)
end

function provider:get(vehicle)
    return exports.LegacyFuel:GetFuel(vehicle)
end
