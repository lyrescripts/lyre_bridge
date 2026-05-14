local provider = LyreBridge.registerProvider("client", "vehicle_keys", "qb_vehiclekeys", 20)

function provider:detect()
    return bridge.core.isStarted("qb-vehiclekeys")
end

function provider:give(vehicle, plate)
    TriggerEvent("vehiclekeys:client:SetOwner", plate)
end

function provider:remove(plate)
    TriggerServerEvent("qb-vehiclekeys:server:AcquireVehicleKeys", plate)
end
