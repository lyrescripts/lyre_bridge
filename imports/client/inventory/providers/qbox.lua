LyreBridge.registerProvider("client", "inventory", {
    name = "qbox",
    priority = 120,
    isAvailable = function(self, context)
        return context.framework == "QBOX"
            and context.object
            and type(context.object.GetPlayerData) == "function"
    end,
    hasItem = function(self, context)
        local playerData = context.object:GetPlayerData()
        local items = playerData and playerData.items
        if type(items) ~= "table" then
            return true, false
        end

        for _, itemData in pairs(items) do
            if type(itemData) == "table" and itemData.name == context.itemName then
                return true, ((itemData.count or itemData.amount) or 0) >= context.amount
            end
        end

        return true, false
    end,
})
