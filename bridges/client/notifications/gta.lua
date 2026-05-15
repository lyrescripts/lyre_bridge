local provider = LyreBridge.registerProvider("client", "notifications", "gta", 1000)

---Always active; the native GTA feed is the universal fallback.
---@return boolean
function provider:detect()
    return true
end

---Display a standard GTA feed notification.
---@param message string
function provider:show(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

---Display a persistent help-text notification (top-left native style).
---@param message string
function provider:help(message)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end
