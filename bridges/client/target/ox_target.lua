local provider = LyreBridge.registerProvider("client", "target", "ox_target", 10)

function provider:detect()
    return bridge.core.isStarted("ox_target")
end

function provider:addLocalEntity(entity, options)
    exports.ox_target:addLocalEntity(entity, options)
end

function provider:removeLocalEntity(entity, optionNames)
    exports.ox_target:removeLocalEntity(entity, optionNames)
end

function provider:addSphereZone(zone)
    return exports.ox_target:addSphereZone(zone)
end

function provider:removeZone(id)
    exports.ox_target:removeZone(id)
end
