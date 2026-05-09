LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "F_RealCarKeysSystem",
    resource = "F_RealCarKeysSystem",
    priority = 110,
    give = function(self, context)
        TriggerServerEvent("F_RealCarKeysSystem:generateVehicleKeys", context.plate)
        return true
    end,
})
