-- Example: route help notifications to a custom UI.
--[[
LyreBridge.registerModule("client", "customHelp", function()
    return {
        show = function(message)
            exports["my_ui"]:ShowHelp(message)
            return true
        end,
    }
end)
]]
