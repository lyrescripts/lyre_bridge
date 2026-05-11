local provider = LyreBridge.registerProvider("client", "vehicle_keys", "mrnewb_vehiclekeys", 50)

function provider:detect()
    return bridge.core:isStarted("MrNewbVehicleKeys")
end

function provider:give(vehicle, plate)
    exports.MrNewbVehicleKeys:GiveKeys(vehicle)
end

function provider:remove(plate)
    exports.MrNewbVehicleKeys:RemoveKeys(plate)
end
