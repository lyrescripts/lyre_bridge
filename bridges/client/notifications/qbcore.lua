local provider = LyreBridge.registerProvider("client", "notifications", "qbcore", 60)

---Active when the `qb-core` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-core")
end

---Cache the QBCore core object for later calls.
function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

---Display a standard QBCore notification.
---@param message string
---@param notificationType? BridgeNotificationType QBCore variant (`primary`, `success`, `error`).
---@param duration? integer Milliseconds to keep the notification visible.
function provider:show(message, notificationType, duration)
    self.object.Functions.Notify(message, notificationType or "primary", duration or 5000)
end

---Display a persistent help-text notification (top-left native style).
---@param message string
function provider:help(message)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end
