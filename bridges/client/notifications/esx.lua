local provider = LyreBridge.registerProvider("client", "notifications", "esx", 50)

---Active when the `es_extended` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("es_extended")
end

---Cache the ESX shared object for later calls.
function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

---Display a standard notification.
---@param message string
---@param notificationType? BridgeNotificationType Color/icon hint forwarded to ESX.
---@param duration? integer Milliseconds to keep the notification visible.
function provider:show(message, notificationType, duration)
    self.object.ShowNotification(message, notificationType, duration)
end

---Display a persistent help-text notification (top-left ESX style).
---@param message string
function provider:help(message)
    self.object.ShowHelpNotification(message)
end
