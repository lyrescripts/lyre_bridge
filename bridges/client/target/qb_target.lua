local provider = LyreBridge.registerProvider("client", "target", "qb_target", 50)

---Convert bridge target options to qb-target options.
---@param options BridgeTargetOption[] Bridge target options.
---@return table[] options Converted options.
function provider:convertOptions(options)
    local converted = {}
    for index, option in ipairs(options) do
        converted[index] = {
            name = option.name,
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

    return converted
end

---Resolve the interaction distance for qb-target options.
---@param options BridgeTargetOption[] Bridge target options.
---@param fallback? number Default distance.
---@return number distance Resolved distance.
function provider:resolveDistance(options, fallback)
    local distance = fallback or 2.5
    for _, option in ipairs(options) do
        if tonumber(option.distance) then
            distance = tonumber(option.distance)
            break
        end
    end

    return distance
end

---Active when `qb-target` is started or provided by another resource.
---@return boolean
function provider:detect()
    return bridge.core.isAvailable("qb-target")
end

---Attach target options to a local entity.
---@param entity integer
---@param options BridgeTargetOption[]
function provider:addLocalEntity(entity, options)
    exports["qb-target"]:AddTargetEntity(entity, { options = self:convertOptions(options), distance = self:resolveDistance(options, 2.5) })
end

---Detach target options from `entity`.
---@param entity integer
---@param optionNames? string[] When provided, only these options are removed.
function provider:removeLocalEntity(entity, optionNames)
    exports["qb-target"]:RemoveTargetEntity(entity, optionNames)
end

---Attach target options to every vehicle.
---@param options BridgeTargetOption[]
function provider:addGlobalVehicle(options)
    exports["qb-target"]:AddGlobalVehicle({ options = self:convertOptions(options), distance = self:resolveDistance(options, 2.5) })
end

---Detach global vehicle target options.
---@param optionNames? string[] When provided, only these options are removed.
function provider:removeGlobalVehicle(optionNames)
    exports["qb-target"]:RemoveGlobalVehicle(optionNames)
end

---Register a spherical interaction zone.
---@param zone { id: string, coords: vector3, radius: number, options: BridgeTargetOption[] }
---@return string? id
function provider:addSphereZone(zone)
    local zoneName = zone.id or zone.name
    if not zoneName then return nil end
    local distance = zone.distance or self:resolveDistance(zone.options, 2.5)

    exports["qb-target"]:AddCircleZone(zoneName, zone.coords, zone.radius, {
        name = zoneName,
        debugPoly = zone.debug or false,
    }, { options = self:convertOptions(zone.options), distance = distance })
    return zoneName
end

---Remove a previously-registered zone.
---@param id string
function provider:removeZone(id)
    exports["qb-target"]:RemoveZone(id)
end
