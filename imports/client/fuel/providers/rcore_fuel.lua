LyreBridge.registerProvider("client", "fuel", {
    name = "rcore_fuel",
    resource = "rcore_fuel",
    priority = 170,
    set = function(self, context, vehicle, fuel)
        exports["rcore_fuel"]:SetVehicleFuel(vehicle, fuel)
        return true
    end,
})
