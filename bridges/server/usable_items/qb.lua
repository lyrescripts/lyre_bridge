local provider = LyreBridge.registerProvider("server", "usable_items", "qb", 50)

---Active when `qb-core` owns item usage (no ox_inventory or qs-inventory).
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-core")
    and not bridge.core.isStarted("ox_inventory")
    and not bridge.core.isStarted("qs-inventory")
end

---Cache the QBCore core object for later calls.
function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

---Register a callback fired when the player uses `itemName`.
---@param itemName string
---@param callback fun(source: integer, item?: table)
function provider:register(itemName, callback)
    self.object.Functions.CreateUseableItem(itemName, function(source)
        callback(source)
    end)
end
