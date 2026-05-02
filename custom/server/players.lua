-- Example: wrap the normalized player module with project-specific helpers.
--[[
LyreBridge.registerModule("server", "projectPlayers", function()
    local players = LyreBridge.getModule("server", "players")

    return {
        get = function(bridge, source)
            return players.getPlayerFromId(bridge, source)
        end,
        notify = function(bridge, source, message)
            return players.showNotification(bridge, source, message, "inform", 5000)
        end,
    }
end)
]]
