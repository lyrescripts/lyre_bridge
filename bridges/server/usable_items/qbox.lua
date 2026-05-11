local provider = LyreBridge.registerProvider("server", "usable_items", "qbox", 30)

function provider:detect()
    return bridge.core:isStarted("qbx_core")
    and not bridge.core:isStarted("ox_inventory")
    and not bridge.core:isStarted("qs-inventory")
end

function provider:register(itemName, callback)
    exports.qbx_core:CreateUseableItem(itemName, function(source)
        callback(source)
    end)
end
