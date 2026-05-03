LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "MrNewbVehicleKeys",
    resource = "MrNewbVehicleKeys",
    priority = 100,
    give = function(self, context)
        exports["MrNewbVehicleKeys"]:GiveKeysByPlate(context.plate)
        return true
    end,
})
