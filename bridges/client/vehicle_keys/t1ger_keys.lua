local provider = LyreBridge.registerProvider("client", "vehicle_keys", "t1ger_keys", 90)

function provider:detect()
    return bridge.core:isStarted("t1ger_keys")
end

function provider:give(vehicle, plate)
    TriggerServerEvent("t1ger_keys:server:GiveKey", plate)
end

function provider:remove(plate)
    TriggerServerEvent("t1ger_keys:server:RemoveKey", plate)
end
