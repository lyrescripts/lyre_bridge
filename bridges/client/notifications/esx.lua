local provider = LyreBridge.registerProvider("client", "notifications", "esx", 50)

function provider:detect()
    return bridge.core:isStarted("es_extended")
end

function provider:init()
    self.object = exports["es_extended"]:getSharedObject()
end

function provider:show(message, notificationType, duration)
    self.object.ShowNotification(message, notificationType, duration)
end

function provider:help(message)
    self.object.ShowHelpNotification(message)
end
