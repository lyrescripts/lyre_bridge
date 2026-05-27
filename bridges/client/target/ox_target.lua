local provider = LyreBridge.registerProvider("client", "target", "ox_target", 10)

---Active when `ox_target` is started or provided by another resource
---(e.g. `lyre_context` declares `provide "ox_target"`).
---@return boolean
function provider:detect()
    return bridge.core.isAvailable("ox_target")
end

---Attach target options to a local entity.
---@param entity integer
---@param options BridgeTargetOption[]
function provider:addLocalEntity(entity, options)
    exports.ox_target:addLocalEntity(entity, options)
end

---Detach target options from `entity`.
---@param entity integer
---@param optionNames? string[] When provided, only these options are removed.
function provider:removeLocalEntity(entity, optionNames)
    exports.ox_target:removeLocalEntity(entity, optionNames)
end

---Attach target options to every vehicle.
---@param options BridgeTargetOption[]
function provider:addGlobalVehicle(options)
    exports.ox_target:addGlobalVehicle(options)
end

---Detach global vehicle target options.
---@param optionNames? string[] When provided, only these options are removed.
function provider:removeGlobalVehicle(optionNames)
    exports.ox_target:removeGlobalVehicle(optionNames)
end

---Register a spherical interaction zone.
---@param zone { id: string, coords: vector3, radius: number, options: BridgeTargetOption[] }
---@return string? id
function provider:addSphereZone(zone)
    return exports.ox_target:addSphereZone(zone)
end

---Remove a previously-registered zone.
---@param id string
function provider:removeZone(id)
    exports.ox_target:removeZone(id)
end
