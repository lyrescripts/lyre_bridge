local provider = LyreBridge.registerProvider("client", "vehicle_keys", "qbx_vehiclekeys", 10)

function provider:detect()
    return bridge.core:isStarted("qbx_vehiclekeys")
end

function provider:give(vehicle, plate)
    TriggerEvent("qbx_vehiclekeys:client:setOwner", plate)
end

function provider:remove(plate)
    TriggerServerEvent("qbx_vehiclekeys:server:removeKeys", plate)
end
