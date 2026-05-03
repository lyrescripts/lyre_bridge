LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "t1ger_keys",
    resource = "t1ger_keys",
    priority = 130,
    give = function(self, context)
        exports["t1ger_keys"]:GiveTemporaryKeys(context.plate, context.model, context.options.keyType or "temporary")
        return true
    end,
})
