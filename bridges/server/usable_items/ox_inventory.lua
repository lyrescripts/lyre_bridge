local provider = LyreBridge.registerProvider("server", "usable_items", "ox_inventory", 10)

---Active when the `ox_inventory` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("ox_inventory")
end

---Register a callback fired when the player uses `itemName`.
---@param itemName string
---@param callback fun(source: integer, item?: table)
function provider:register(itemName, callback)
    exports.ox_inventory:registerHook("usingItem", function(payload)
        callback(payload.source, payload)
        return true
    end, { itemFilter = { [itemName] = true } })
end
