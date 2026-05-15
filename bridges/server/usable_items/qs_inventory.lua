local provider = LyreBridge.registerProvider("server", "usable_items", "qs_inventory", 20)

---Active when `qs-inventory` is running and ox_inventory is not.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qs-inventory")
    and not bridge.core.isStarted("ox_inventory")
end

---Register a callback fired when the player uses `itemName`.
---@param itemName string
---@param callback fun(source: integer, item?: table)
function provider:register(itemName, callback)
    exports["qs-inventory"]:CreateUsableItem(itemName, function(source)
        callback(source)
    end)
end
