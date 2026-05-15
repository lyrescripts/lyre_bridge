local provider = LyreBridge.registerProvider("server", "usable_items", "esx", 70)

---Active when `es_extended` owns item usage (no ox_inventory or qs-inventory).
---@return boolean
function provider:detect()
    return bridge.core.isStarted("es_extended")
    and not bridge.core.isStarted("ox_inventory")
    and not bridge.core.isStarted("qs-inventory")
end

---Cache the ESX shared object for later calls.
function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

---Register a callback fired when the player uses `itemName`.
---@param itemName string
---@param callback fun(source: integer, item?: table)
function provider:register(itemName, callback)
    self.object.RegisterUsableItem(itemName, function(source)
        callback(source)
    end)
end
