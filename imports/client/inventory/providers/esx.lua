LyreBridge.registerProvider("client", "inventory", {
    name = "esx",
    priority = 100,
    isAvailable = function(self, context)
        return context.framework == "ESX"
            and context.object
            and type(context.object.GetPlayerData) == "function"
    end,
    hasItem = function(self, context)
        local playerData = context.object.GetPlayerData()
        local inventory = playerData and playerData.inventory
        if type(inventory) ~= "table" then
            return true, false
        end

        local itemData = inventory[context.itemName]
        if not itemData then
            for _, value in pairs(inventory) do
                if type(value) == "table" and value.name == context.itemName then
                    itemData = value
                    break
                end
            end
        end

        return true, ((itemData and (itemData.count or itemData.amount)) or 0) >= context.amount
    end,
})
