local provider = LyreBridge.registerProvider("client", "notifications", "qbcore", 60)

function provider:detect()
    return bridge.core:isStarted("qb-core")
end

function provider:init()
    self.object = exports["qb-core"]:GetCoreObject()
end

function provider:show(message, notificationType, duration)
    self.object.Functions.Notify(message, notificationType or "primary", duration or 5000)
end

function provider:help(message)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end
