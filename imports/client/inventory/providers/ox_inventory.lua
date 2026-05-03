LyreBridge.registerProvider("client", "inventory", {
    name = "ox_inventory",
    resource = "ox_inventory",
    priority = 10,
    hasItem = function(self, context)
        if type(context.itemName) ~= "string" or context.itemName == "" then
            return false
        end

        local count = exports.ox_inventory:Search("count", context.itemName)
        return true, (tonumber(count) or 0) >= context.amount
    end,
})
