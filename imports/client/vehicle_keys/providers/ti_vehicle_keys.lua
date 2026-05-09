LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "ti_vehicleKeys",
    resource = "ti_vehicleKeys",
    priority = 120,
    give = function(self, context)
        exports["ti_vehicleKeys"]:addTemporaryVehicle(context.plate)
        return true
    end,
})
