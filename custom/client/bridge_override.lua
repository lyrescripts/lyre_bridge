-- Example: override a client bridge method after setup.
--[[
CreateThread(function()
    while not bridge do
        Wait(0)
    end

    function bridge:showNotification(message, notificationType, duration)
        return LyreBridge.getModule("client", "notifications").show(message, notificationType, duration, self)
    end
end)
]]
