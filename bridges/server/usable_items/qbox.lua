local provider = LyreBridge.registerProvider("server", "usable_items", "qbox", 30)

---Active when `qbx_core` owns item usage (no ox_inventory or qs-inventory).
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qbx_core")
    and not bridge.core.isStarted("ox_inventory")
    and not bridge.core.isStarted("qs-inventory")
end

---Register a callback fired when the player uses `itemName`.
---@param itemName string
---@param callback fun(source: integer, item?: table)
function provider:register(itemName, callback)
    exports.qbx_core:CreateUseableItem(itemName, function(source)
        callback(source)
    end)
end
