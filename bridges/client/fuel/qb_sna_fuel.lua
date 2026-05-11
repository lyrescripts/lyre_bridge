local provider = LyreBridge.registerProvider("client", "fuel", "qb_sna_fuel", 100)

function provider:detect()
    return bridge.core:isStarted("qb-sna-fuel")
end

function provider:set(vehicle, fuel)
    exports["qb-sna-fuel"]:SetFuel(vehicle, fuel)
end

function provider:get(vehicle)
    return exports["qb-sna-fuel"]:GetFuel(vehicle)
end
