-- Example: centralize admin permission checks.
--[[
LyreBridge.registerModule("server", "adminGroups", function()
    return {
        hasPermission = function(player, groups)
            local group = player.raw and player.raw.getGroup and player.raw.getGroup()
            return group and groups[group] == true
        end,
    }
end)
]]
