local provider = LyreBridge.registerProvider("server", "usable_items", "esx", 70)

function provider:detect()
    return bridge.core.isStarted("es_extended")
    and not bridge.core.isStarted("ox_inventory")
    and not bridge.core.isStarted("qs-inventory")
end

function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

function provider:register(itemName, callback)
    self.object.RegisterUsableItem(itemName, function(source)
        callback(source)
    end)
end
