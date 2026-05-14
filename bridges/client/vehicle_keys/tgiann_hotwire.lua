local provider = LyreBridge.registerProvider("client", "vehicle_keys", "tgiann_hotwire", 100)

function provider:detect()
    return bridge.core.isStarted("tgiann-hotwire")
end

function provider:give(vehicle, plate)
    exports["tgiann-hotwire"]:GiveKey(plate)
end

function provider:remove(plate)
    exports["tgiann-hotwire"]:RemoveKey(plate)
end
