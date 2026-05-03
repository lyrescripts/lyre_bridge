LyreBridge.registerProvider("server", "usableItems", {
    name = "qs-inventory",
    resource = "qs-inventory",
    priority = 20,
    register = function(self, context)
        exports["qs-inventory"]:CreateUsableItem(context.itemName, context.callback)
        return true, true
    end,
})
