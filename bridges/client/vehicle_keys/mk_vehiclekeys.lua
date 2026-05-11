local provider = LyreBridge.registerProvider("client", "vehicle_keys", "mk_vehiclekeys", 70)

function provider:detect()
    return bridge.core:isStarted("mk_vehiclekeys")
end

function provider:give(vehicle, plate)
    exports.mk_vehiclekeys:AddKey(vehicle)
end

function provider:remove(plate)
    exports.mk_vehiclekeys:RemoveKey(plate)
end
