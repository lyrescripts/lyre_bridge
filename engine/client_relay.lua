---Client-side relay for server-initiated bridge calls. Server code fires
---`TriggerClientEvent("lyre_bridge:<module>:<method>", playerId, ...)` and
---the handler routes to the matching `bridge.<module>` method so the active
---provider wins instead of the framework's built-in UI.

---Display a notification through the active client-side notifications provider.
---Fired from the server with `TriggerClientEvent("lyre_bridge:notifications:show", source, message, type, duration)`.
---@param message string
---@param notificationType? BridgeNotificationType
---@param duration? integer
RegisterNetEvent("lyre_bridge:notifications:show", function(message, notificationType, duration)
    bridge.notifications.show(message, notificationType, duration)
end)
