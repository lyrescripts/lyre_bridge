local provider = LyreBridge.registerProvider("client", "target", "qb_target", 50)

---Active when the `qb-target` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("qb-target")
end

---Attach target options to a local entity.
---@param entity integer
---@param options BridgeTargetOption[]
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

    exports["qb-target"]:AddTargetEntity(entity, { options = converted, distance = distance })
end

---Detach target options from `entity`.
---@param entity integer
---@param optionNames? string[] When provided, only these options are removed.
function provider:removeLocalEntity(entity, optionNames)
    exports["qb-target"]:RemoveTargetEntity(entity, optionNames)
end

---Register a spherical interaction zone.
---@param zone { id: string, coords: vector3, radius: number, options: BridgeTargetOption[] }
---@return string? id
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

    exports["qb-target"]:AddCircleZone(zone.name, zone.coords, zone.radius, {
        name = zone.name,
        debugPoly = zone.debug or false,
    }, { options = converted, distance = distance })
    return zone.name
end

---Remove a previously-registered zone.
---@param id string
function provider:removeZone(id)
    exports["qb-target"]:RemoveZone(id)
end
