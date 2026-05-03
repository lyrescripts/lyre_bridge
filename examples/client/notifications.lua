-- Example: replace notifications with your own UI resource.
--[[
LyreBridge.registerModule("client", "notifications", function()
    return {
        show = function(message, notificationType, duration)
            exports["my_notifications"]:Send(message, notificationType or "inform", duration or 5000)
            return true
        end,
        help = function(message)
            exports["my_notifications"]:Help(message)
            return true
        end,
    }
end)
]]
