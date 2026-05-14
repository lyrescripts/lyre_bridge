local provider = LyreBridge.registerProvider("server", "usable_items", "qb", 50)

function provider:detect()
    return bridge.core.isStarted("qb-core")
    and not bridge.core.isStarted("ox_inventory")
    and not bridge.core.isStarted("qs-inventory")
end

function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

function provider:register(itemName, callback)
    self.object.Functions.CreateUseableItem(itemName, function(source)
        callback(source)
    end)
end
