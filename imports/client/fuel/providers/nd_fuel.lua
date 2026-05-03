LyreBridge.registerProvider("client", "fuel", {
    name = "ND_Fuel",
    resource = "ND_Fuel",
    priority = 90,
    set = function(self, context, vehicle, fuel)
        SetVehicleFuelLevel(vehicle, fuel)
        DecorSetFloat(vehicle, "_ANDY_FUEL_DECORE_", fuel)
        return true
    end,
})
