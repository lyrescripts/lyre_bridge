LyreBridge.registerProvider("server", "usableItems", {
    name = "qb",
    priority = 110,
    isAvailable = function(self, context)
        return context.framework == "QBCORE"
            and context.object
            and context.object.Functions
            and type(context.object.Functions.CreateUseableItem) == "function"
    end,
    register = function(self, context)
        context.object.Functions.CreateUseableItem(context.itemName, function(source, item)
            context.callback(source, item)
        end)
        return true, true
    end,
})
