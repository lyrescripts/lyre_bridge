local provider = LyreBridge.registerProvider("client", "vehicle_keys", "wasabi_carlock", 40)

function provider:detect()
    return bridge.core:isStarted("wasabi_carlock")
end

function provider:give(vehicle, plate)
    exports.wasabi_carlock:GiveKey(plate)
end

function provider:remove(plate)
    exports.wasabi_carlock:RemoveKey(plate)
end
