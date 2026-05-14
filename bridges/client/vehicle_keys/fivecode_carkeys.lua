local provider = LyreBridge.registerProvider("client", "vehicle_keys", "fivecode_carkeys", 80)

function provider:detect()
    return bridge.core.isStarted("5code_carkeys")
end

function provider:give(vehicle, plate)
    exports["5code_carkeys"]:AddKey(plate)
end

function provider:remove(plate)
    exports["5code_carkeys"]:RemoveKey(plate)
end
