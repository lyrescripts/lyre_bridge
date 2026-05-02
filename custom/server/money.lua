-- Example: custom money account aliases.
--[[
LyreBridge.registerModule("server", "money", function()
    local aliases = {
        cash = "money",
        dirty = "black_money",
    }

    return {
        account = function(name)
            return aliases[name] or name
        end,
    }
end)
]]
