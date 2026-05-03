-- Example: normalize inventory calls for all resources.
--[[
LyreBridge.registerModule("server", "inventory", function()
    return {
        addItem = function(source, item, amount, metadata)
            return exports["ox_inventory"]:AddItem(source, item, amount or 1, metadata)
        end,
        removeItem = function(source, item, amount, slot)
            return exports["ox_inventory"]:RemoveItem(source, item, amount or 1, nil, slot)
        end,
        count = function(source, item)
            return exports["ox_inventory"]:Search(source, "count", item) or 0
        end,
    }
end)
]]
