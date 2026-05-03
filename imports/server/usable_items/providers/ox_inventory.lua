LyreBridge.registerProvider("server", "usableItems", {
    name = "ox_inventory",
    resource = "ox_inventory",
    priority = 10,
    register = function(self, context)
        exports.ox_inventory:RegisterUsableItem(context.itemName, context.callback)
        return true, true
    end,
})
