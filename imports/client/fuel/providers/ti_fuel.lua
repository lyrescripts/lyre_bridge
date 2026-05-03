LyreBridge.registerProvider("client", "fuel", {
    name = "ti_fuel",
    resource = "ti_fuel",
    priority = 70,
    set = function(self, context, vehicle, fuel)
        exports["ti_fuel"]:setFuel(vehicle, fuel, "RON91")
        return true
    end,
})
