local provider = LyreBridge.registerProvider("client", "notifications", "qbox", 40)

function provider:detect()
    return bridge.core.isStarted("qbx_core") and bridge.core.isStarted("ox_lib") and lib and type(lib.notify) == "function"
end

function provider:show(message, notificationType, duration)
    lib.notify({
        description = message,
        type = notificationType or "inform",
        duration = duration or 5000,
    })
end

function provider:help(message)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end
