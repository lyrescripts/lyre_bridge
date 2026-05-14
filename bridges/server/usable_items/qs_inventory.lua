local provider = LyreBridge.registerProvider("server", "usable_items", "qs_inventory", 20)

function provider:detect()
    return bridge.core.isStarted("qs-inventory")
    and not bridge.core.isStarted("ox_inventory")
end

function provider:register(itemName, callback)
    exports["qs-inventory"]:CreateUsableItem(itemName, function(source)
        callback(source)
    end)
end
