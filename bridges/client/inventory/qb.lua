local provider = LyreBridge.registerProvider("client", "inventory", "qb", 50)

function provider:detect()
    return bridge.core:isStarted("qb-core")
    and not bridge.core:isStarted("ox_inventory")
end

function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

function provider:hasItem(itemName, amount)
    local playerData = self.object.Functions.GetPlayerData()
    local items = playerData and playerData.items or {}
    local total = 0
    for _, item in pairs(items) do
        if item and item.name == itemName then
            total = total + (item.amount or item.count or 1)
        end
    end
    return total >= (amount or 1)
end
