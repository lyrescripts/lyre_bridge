local provider = LyreBridge.registerProvider("server", "usable_items", "ox_inventory", 10)

function provider:detect()
    return bridge.core:isStarted("ox_inventory")
end

function provider:register(itemName, callback)
    exports.ox_inventory:registerHook("usingItem", function(payload)
        callback(payload.source, payload)
        return true
    end, { itemFilter = { [itemName] = true } })
end
