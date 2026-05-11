local provider = LyreBridge.registerProvider("client", "target", "qtarget", 60)

function provider:detect()
    return bridge.core:isStarted("qtarget")
end

function provider:addLocalEntity(entity, options)
    local converted = {}
    for index, option in ipairs(options) do
        converted[index] = {
            label = option.label,
            icon = option.icon,
            event = option.event or option.serverEvent,
            type = option.serverEvent and "server" or option.type,
            item = option.item,
            job = option.job,
            gang = option.gang,
            canInteract = option.canInteract,
            action = option.action or (option.onSelect and function(en)
                option.onSelect({ entity = en })
            end),
        }
    end

    local distance = 2.5
    for _, option in ipairs(options) do
        if tonumber(option.distance) then
            distance = tonumber(option.distance)
            break
        end
    end

    exports.qtarget:AddTargetEntity(entity, { options = converted, distance = distance })
end

function provider:removeLocalEntity(entity, optionNames)
    exports.qtarget:RemoveTargetEntity(entity, optionNames)
end

function provider:addSphereZone(zone)
    local converted = {}
    for index, option in ipairs(zone.options) do
        converted[index] = {
            label = option.label,
            icon = option.icon,
            event = option.event or option.serverEvent,
            type = option.serverEvent and "server" or option.type,
            item = option.item,
            job = option.job,
            gang = option.gang,
            canInteract = option.canInteract,
            action = option.action or (option.onSelect and function(en)
                option.onSelect({ entity = en })
            end),
        }
    end

    local distance = zone.distance or 2.5
    if not zone.distance then
        for _, option in ipairs(zone.options) do
            if tonumber(option.distance) then
                distance = tonumber(option.distance)
                break
            end
        end
    end

    exports.qtarget:AddCircleZone(zone.name, zone.coords, zone.radius, {
        name = zone.name,
        debugPoly = zone.debug or false,
    }, { options = converted, distance = distance })
    return zone.name
end

function provider:removeZone(id)
    exports.qtarget:RemoveZone(id)
end
