LyreBridge.registerProvider("server", "usableItems", {
    name = "qbox",
    priority = 120,
    isAvailable = function(self, context)
        return context.framework == "QBOX"
            and context.object
            and type(context.object.CreateUseableItem) == "function"
    end,
    register = function(self, context)
        context.object:CreateUseableItem(context.itemName, function(source, item)
            context.callback(source, item)
        end)
        return true, true
    end,
})
