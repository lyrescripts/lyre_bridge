local provider = LyreBridge.registerProvider("client", "vehicle_keys", "renewed_vehiclekeys", 60)

function provider:detect()
    return bridge.core:isStarted("Renewed-Vehiclekeys")
end

function provider:give(vehicle, plate)
    TriggerServerEvent("Renewed-Vehiclekeys:server:GiveKeys", plate)
end

function provider:remove(plate)
    TriggerServerEvent("Renewed-Vehiclekeys:server:RemoveKeys", plate)
end
