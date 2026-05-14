local provider = LyreBridge.registerProvider("client", "inventory", "ox_inventory", 10)

function provider:detect()
    return bridge.core.isStarted("ox_inventory")
end

function provider:hasItem(itemName, amount)
    local count = exports.ox_inventory:Search("count", itemName) or 0
    return count >= (amount or 1)
end
