LyreBridge.registerProvider("client", "fuel", {
    name = "ti_fuel",
    resource = "ti_fuel",
    priority = 150,
    set = function(self, context, vehicle, fuel)
        exports["ti_fuel"]:setFuel(vehicle, fuel, "RON91")
        return true
    end,
})
