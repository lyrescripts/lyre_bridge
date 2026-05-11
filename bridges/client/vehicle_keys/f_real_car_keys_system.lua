local provider = LyreBridge.registerProvider("client", "vehicle_keys", "f_real_car_keys_system", 110)

function provider:detect()
    return bridge.core:isStarted("f-realCarKeysSystem")
end

function provider:give(vehicle, plate)
    exports["f-realCarKeysSystem"]:GiveKeys(plate)
end

function provider:remove(plate)
    exports["f-realCarKeysSystem"]:RemoveKeys(plate)
end
