LyreBridge.registerProvider("server", "dispatch", {
    name = "custom",
    priority = 1,
    isAvailable = function(self, context)
        return type(context.options.customServer) == "function"
            or type(context.options.custom) == "function"
    end,
    send = function(self, context)
        local callback = context.options.customServer or context.options.custom
        return true, callback(context.payload, context.options.data) == true
    end,
})
