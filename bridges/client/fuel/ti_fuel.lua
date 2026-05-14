local provider = LyreBridge.registerProvider("client", "fuel", "ti_fuel", 150)

function provider:detect()
    return bridge.core.isStarted("ti_fuel")
end

function provider:set(vehicle, fuel)
    exports.ti_fuel:setFuel(vehicle, fuel, "RON91")
end

function provider:get(vehicle)
    return exports.ti_fuel:getFuel(vehicle)
end
