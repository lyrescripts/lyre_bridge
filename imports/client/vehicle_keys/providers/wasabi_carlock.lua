LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "wasabi_carlock",
    resource = "wasabi_carlock",
    priority = 150,
    give = function(self, context)
        exports["wasabi_carlock"]:GiveKey(context.plate)
        return true
    end,
})
