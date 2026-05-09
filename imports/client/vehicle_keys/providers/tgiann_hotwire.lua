LyreBridge.registerProvider("client", "vehicleKeys", {
    name = "tgiann-hotwire",
    resource = "tgiann-hotwire",
    priority = 100,
    give = function(self, context)
        exports["tgiann-hotwire"]:GiveKeyPlate(context.plate, true)
        return true
    end,
})
