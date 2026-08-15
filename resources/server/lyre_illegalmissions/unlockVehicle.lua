LyreBridge.registerCustomResourceFunction("lyre_illegalmissions", "unlockVehicle", function(playerSource, vehicleNetworkId)
    -- Called right after a car theft target has been unlocked by the script itself.
    -- The return value is ignored, so this hook only adds behaviour, for example
    -- handing the vehicle keys to the thief through your own key system.
    -- playerSource: number, the player who picked the lock
    -- vehicleNetworkId: number, network id of the stolen vehicle
end)
