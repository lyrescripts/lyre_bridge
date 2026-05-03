LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "vehicles_keys",
    resource = "vehicles_keys",
    priority = 10,
    give = function(self, context)
        TriggerServerEvent("vehicles_keys:selfGiveVehicleKeys", context.plate)
        return true
    end,
})
