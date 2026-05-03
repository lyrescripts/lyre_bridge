LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "qs-vehiclekeys",
    resource = "qs-vehiclekeys",
    priority = 120,
    give = function(self, context)
        exports["qs-vehiclekeys"]:GiveKeys(context.plate, context.model, true)
        return true
    end,
})
