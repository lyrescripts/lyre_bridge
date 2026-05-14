local provider = LyreBridge.registerProvider("client", "inventory", "esx", 70)

function provider:detect()
    return bridge.core.isStarted("es_extended")
    and not bridge.core.isStarted("ox_inventory")
end

function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

function provider:hasItem(itemName, amount)
    local playerData = self.object.GetPlayerData()
    local inventory = playerData and playerData.inventory or {}
    for _, item in ipairs(inventory) do
        if item.name == itemName and (item.count or 0) >= (amount or 1) then
            return true
        end
    end
    return false
end
