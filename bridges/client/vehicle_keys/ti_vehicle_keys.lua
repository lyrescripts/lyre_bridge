local provider = LyreBridge.registerProvider("client", "vehicle_keys", "ti_vehicle_keys", 120)

function provider:detect()
    return bridge.core:isStarted("ti_vehicle_keys")
end

function provider:give(vehicle, plate)
    exports.ti_vehicle_keys:GiveKey(plate)
end

function provider:remove(plate)
    exports.ti_vehicle_keys:RemoveKey(plate)
end
