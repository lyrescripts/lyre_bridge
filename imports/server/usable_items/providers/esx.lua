LyreBridge.registerProvider("server", "usableItems", {
    name = "esx",
    priority = 100,
    isAvailable = function(self, context)
        return context.framework == "ESX"
            and context.object
            and type(context.object.RegisterUsableItem) == "function"
    end,
    register = function(self, context)
        context.object.RegisterUsableItem(context.itemName, function(playerId, usedItemName, itemData)
            context.callback(playerId, itemData or usedItemName)
        end)
        return true, true
    end,
})
