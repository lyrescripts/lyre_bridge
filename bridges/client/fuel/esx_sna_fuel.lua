local provider = LyreBridge.registerProvider("client", "fuel", "esx_sna_fuel", 80)

function provider:detect()
    return bridge.core.isStarted("esx-sna-fuel")
end

function provider:set(vehicle, fuel)
    exports["esx-sna-fuel"]:SetFuel(vehicle, fuel)
end

function provider:get(vehicle)
    return exports["esx-sna-fuel"]:GetFuel(vehicle)
end
