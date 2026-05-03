LyreBridge.registerProvider("server", "dispatch", {
    name = "lb-tablet",
    resource = "lb-tablet",
    priority = 140,
    send = function(self, context)
        exports["lb-tablet"]:AddDispatch(context.payload)
        return true, true
    end,
})
