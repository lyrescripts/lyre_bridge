local provider = LyreBridge.registerProvider("client", "vehicle_keys", "qs_vehiclekeys", 30)

function provider:detect()
    return bridge.core:isStarted("qs-vehiclekeys")
end

function provider:give(vehicle, plate)
    exports["qs-vehiclekeys"]:GiveKeys(plate)
end

function provider:remove(plate)
    exports["qs-vehiclekeys"]:RemoveKeys(plate)
end
