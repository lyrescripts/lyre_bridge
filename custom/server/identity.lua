-- Example: add a shared identity helper.
--[[
LyreBridge.registerModule("server", "identity", function()
    return {
        fullName = function(player)
            return player.getName and player.getName() or "Unknown"
        end,
        identifier = function(player)
            return player.getIdentifier and player.getIdentifier() or nil
        end,
    }
end)
]]
