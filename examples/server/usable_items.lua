-- Example: register usable items through the active framework.
--[[
LyreBridge.registerModule("server", "usableItems", function()
    return {
        register = function(bridge, item, handler)
            if bridge.__lyre.framework == "ESX" then
                bridge.object.RegisterUsableItem(item, handler)
                return true
            end

            if bridge.__lyre.framework == "QBCORE" then
                bridge.object.Functions.CreateUseableItem(item, handler)
                return true
            end

            return false
        end,
    }
end)
]]
