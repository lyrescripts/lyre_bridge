local provider = LyreBridge.registerProvider("client", "notifications", "ox_lib", 10)

---Active when `ox_lib` is started and exposes `lib.notify`.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("ox_lib") and lib and type(lib.notify) == "function"
end

---Display a standard ox_lib notification.
---@param message string
---@param notificationType? BridgeNotificationType ox_lib variant (`inform`, `success`, ...).
---@param duration? integer Milliseconds to keep the notification visible.
function provider:show(message, notificationType, duration)
    lib.notify({
        description = message,
        type = notificationType or "inform",
        duration = duration or 5000,
    })
end

---Display a persistent help-text notification (top-left native style).
---@param message string
function provider:help(message)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end
