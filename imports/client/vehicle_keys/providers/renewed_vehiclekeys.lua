LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "Renewed-Vehiclekeys",
    resource = "Renewed-Vehiclekeys",
    priority = 170,
    give = function(self, context)
        exports["Renewed-Vehiclekeys"]:addKey(context.plate)
        return true
    end,
})
