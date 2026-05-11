local provider = LyreBridge.registerProvider("client", "notifications", "gta", 1000)

function provider:detect()
    return true
end

function provider:show(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

function provider:help(message)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end
