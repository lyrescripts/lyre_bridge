LyreBridge = LyreBridge or {}

local Core = LyreBridge

Core.version = Core.version or "1.0.0"
Core.config = Core.config or {}
Core.modules = Core.modules or { shared = {}, client = {}, server = {} }
Core._stateCache = Core._stateCache or {}
Core.resources = Core.resources or {}

local defaultConfig = {
    debug = false,
    failHard = false,
    wrapBridgeCalls = true,
    resourceStateCacheMs = 2500,
    defaultDetectionOrder = { "ESX", "QBOX", "QBCORE", "STANDALONE", "EXAMPLE" },
}

for key, value in pairs(defaultConfig) do
    if Core.config[key] == nil then
        Core.config[key] = value
    end
end

local function readBoolConvar(name, default)
    if type(GetConvar) ~= "function" then
        return default
    end

    local value = string.lower(tostring(GetConvar(name, default and "true" or "false")))
    return value == "true" or value == "1" or value == "yes" or value == "on"
end

local function readNumberConvar(name, default)
    if type(GetConvar) ~= "function" then
        return default
    end

    local value = tonumber(GetConvar(name, tostring(default)))
    return value or default
end

Core.config.debug = readBoolConvar("lyre_bridge:debug", Core.config.debug)
Core.config.failHard = readBoolConvar("lyre_bridge:failHard", Core.config.failHard)
Core.config.wrapBridgeCalls = readBoolConvar("lyre_bridge:wrapCalls", Core.config.wrapBridgeCalls)
Core.config.resourceStateCacheMs = readNumberConvar("lyre_bridge:stateCacheMs", Core.config.resourceStateCacheMs)

local aliases = {
    esx = "ESX",
    ["es_extended"] = "ESX",
    qb = "QBCORE",
    qbcore = "QBCORE",
    ["qb-core"] = "QBCORE",
    qbox = "QBOX",
    qbx = "QBOX",
    ["qbx_core"] = "QBOX",
    standalone = "STANDALONE",
    none = "STANDALONE",
    example = "EXAMPLE",
    custom = "EXAMPLE",
}

local internalBridgeMethods = {
    autoDetect = true,
    init = true,
    safeCall = true,
    getModule = true,
    requireFunctions = true,
}

local function currentResourceName()
    if type(GetCurrentResourceName) == "function" then
        return GetCurrentResourceName()
    end

    return "unknown"
end

local function now()
    if type(GetGameTimer) == "function" then
        return GetGameTimer()
    end

    return math.floor(os.clock() * 1000)
end

local pack = table.pack or function(...)
    return {
        n = select("#", ...),
        ...,
    }
end

local unpack = table.unpack or unpack

local function unpackPacked(values, first)
    return unpack(values, first or 1, values.n or #values)
end

local function contextToString(context)
    if type(context) ~= "table" then
        return context and tostring(context) or ""
    end

    local parts = {}
    for key, value in pairs(context) do
        if type(value) ~= "table" and type(value) ~= "function" then
            parts[#parts + 1] = tostring(key) .. "=" .. tostring(value)
        end
    end

    table.sort(parts)
    return table.concat(parts, " ")
end

function Core.log(level, message, context)
    level = string.upper(level or "info")

    if level == "DEBUG" and not Core.config.debug then
        return
    end

    local suffix = contextToString(context)
    if suffix ~= "" then
        suffix = " {" .. suffix .. "}"
    end

    print(("[lyre_bridge][%s] %s%s"):format(level, tostring(message), suffix))
end

function Core.ok(data, context)
    return {
        ok = true,
        data = data,
        context = context,
    }
end

function Core.fail(code, message, context)
    local failure = {
        ok = false,
        code = code or "unknown_error",
        message = message or "Unknown bridge error",
        context = context,
    }

    Core.log("error", failure.code .. ": " .. failure.message, context)
    return failure
end

function Core.resolveBridgeName(bridgeName)
    if type(bridgeName) ~= "string" then
        return bridgeName
    end

    local lower = string.lower(bridgeName)
    return aliases[lower] or aliases[bridgeName] or string.upper(bridgeName)
end

function Core.isAutoBridge(bridgeName)
    return type(bridgeName) ~= "string" or string.lower(bridgeName) == "auto_detect"
end

function Core.getResourceStateCached(resourceName, ttl)
    if type(resourceName) ~= "string" or resourceName == "" or type(GetResourceState) ~= "function" then
        return "missing"
    end

    ttl = ttl or Core.config.resourceStateCacheMs
    local entry = Core._stateCache[resourceName]
    local currentTime = now()

    if entry and currentTime - entry.at <= ttl then
        return entry.state
    end

    local state = GetResourceState(resourceName)
    Core._stateCache[resourceName] = {
        state = state,
        at = currentTime,
    }

    return state
end

function Core.isStarted(resourceName)
    return Core.getResourceStateCached(resourceName) == "started"
end

function Core.getDetectionOrder(config, options)
    options = options or {}

    if type(options.detectionOrder) == "table" then
        return options.detectionOrder
    end

    if type(config) == "table" and type(config.bridgeAutoDetectOrder) == "table" then
        return config.bridgeAutoDetectOrder
    end

    return Core.config.defaultDetectionOrder
end

function Core.registerResource(resourceName, definition)
    if type(resourceName) ~= "string" or resourceName == "" then
        return false, Core.fail("invalid_resource_registration", "Resource registration expects a non-empty resource name.")
    end

    if type(definition) ~= "table" then
        definition = {}
    end

    definition.name = definition.name or resourceName
    definition.path = definition.path or ("resources/" .. resourceName)
    definition.bridge = definition.bridge or {}
    definition.sql = definition.sql or {}

    Core.resources[resourceName] = definition
    Core.log("debug", "Resource registered.", {
        resource = resourceName,
        path = definition.path,
    })

    return true, definition
end

function Core.getResourceDefinition(resourceName)
    if type(resourceName) ~= "string" then
        return nil
    end

    return Core.resources and Core.resources[resourceName] or nil
end

function Core.listRegisteredResources()
    local names = {}

    for resourceName in pairs(Core.resources or {}) do
        names[#names + 1] = resourceName
    end

    table.sort(names)
    return names
end

function Core.registerModule(side, name, factory)
    if type(side) ~= "string" or type(name) ~= "string" or type(factory) ~= "function" then
        return false, Core.fail("invalid_module_registration", "Module registration expects side, name and factory.")
    end

    Core.modules[side] = Core.modules[side] or {}
    Core.modules[side][name] = {
        factory = factory,
        loaded = false,
        instance = nil,
    }

    return true
end

function Core.getModule(side, name)
    local bucket = Core.modules[side] or {}
    local module = bucket[name] or (Core.modules.shared and Core.modules.shared[name])

    if not module then
        return nil, Core.fail("module_not_found", "Module `" .. tostring(name) .. "` is not registered.", {
            side = side,
            resource = currentResourceName(),
        })
    end

    if module.loaded then
        return module.instance
    end

    local ok, instance = pcall(module.factory)
    if not ok then
        return nil, Core.fail("module_load_failed", "Module `" .. name .. "` failed to load: " .. tostring(instance), {
            side = side,
            resource = currentResourceName(),
        })
    end

    module.loaded = true
    module.instance = instance or {}
    return module.instance
end

function Core.safeBridgeCall(bridge, methodName, ...)
    if type(bridge) ~= "table" or type(bridge[methodName]) ~= "function" then
        return false, Core.fail("missing_bridge_method", "Missing bridge method `" .. tostring(methodName) .. "`.", {
            method = methodName,
            resource = currentResourceName(),
        })
    end

    local response = pack(pcall(bridge[methodName], bridge, ...))
    if response[1] then
        return true, unpackPacked(response, 2)
    end

    return false, Core.fail("bridge_call_failed", "Bridge method `" .. tostring(methodName) .. "` failed: " .. tostring(response[2]), {
        method = methodName,
        resource = currentResourceName(),
        framework = bridge.__lyre and bridge.__lyre.framework or "unknown",
    })
end

function Core.validateBridge(bridge, required, context)
    if type(required) ~= "table" then
        return true
    end

    local missing = {}
    for _, methodName in ipairs(required) do
        if type(bridge[methodName]) ~= "function" then
            missing[#missing + 1] = methodName
        end
    end

    if #missing == 0 then
        return true
    end

    return false, Core.fail("bridge_contract_failed", "Selected bridge is missing: " .. table.concat(missing, ", "), context)
end

function Core.applyModuleDefaults(bridge, context)
    if type(bridge) ~= "table" or type(context) ~= "table" then
        return bridge
    end

    if context.side == "client" then
        if type(bridge.showNotification) ~= "function" then
            function bridge:showNotification(message, notificationType, duration)
                local module = Core.getModule("client", "notifications")
                return module and module.show(message, notificationType, duration, self)
            end
        end

        if type(bridge.showHelpNotification) ~= "function" then
            function bridge:showHelpNotification(message)
                local module = Core.getModule("client", "notifications")
                return module and module.help(message, self)
            end
        end

        if type(bridge.targetAddLocalEntity) ~= "function" then
            function bridge:targetAddLocalEntity(entity, options)
                local module = Core.getModule("client", "target")
                return module and module.addLocalEntity(entity, options)
            end
        end

        if type(bridge.targetRemoveEntity) ~= "function" then
            function bridge:targetRemoveEntity(entity, optionNames)
                local module = Core.getModule("client", "target")
                return module and module.removeEntity(entity, optionNames)
            end
        end

        if type(bridge.targetRemoveLocalEntity) ~= "function" then
            function bridge:targetRemoveLocalEntity(entity, optionNames)
                local module = Core.getModule("client", "target")
                return module and module.removeEntity(entity, optionNames)
            end
        end

        if type(bridge.targetAddSphereZone) ~= "function" then
            function bridge:targetAddSphereZone(...)
                local module = Core.getModule("client", "target")
                return module and module.addSphereZone(...)
            end
        end

        if type(bridge.targetRemoveZone) ~= "function" then
            function bridge:targetRemoveZone(id)
                local module = Core.getModule("client", "target")
                return module and module.removeZone(id)
            end
        end

        if type(bridge.giveVehicleKeys) ~= "function" then
            function bridge:giveVehicleKeys(...)
                local module = Core.getModule("client", "vehicleKeys")
                return module and module.give(...)
            end
        end

        if type(bridge.removeVehicleKeys) ~= "function" then
            function bridge:removeVehicleKeys(plate, options)
                local module = Core.getModule("client", "vehicleKeys")
                return module and module.remove(plate, options)
            end
        end

        if type(bridge.setFuel) ~= "function" then
            function bridge:setFuel(vehicleOrNetId, fuel)
                local module = Core.getModule("client", "fuel")
                return module and module.set(vehicleOrNetId, fuel)
            end
        end

        if type(bridge.getFuel) ~= "function" then
            function bridge:getFuel(vehicleOrNetId)
                local module = Core.getModule("client", "fuel")
                return module and module.get(vehicleOrNetId)
            end
        end

        if type(bridge.progress) ~= "function" then
            function bridge:progress(...)
                local module = Core.getModule("client", "progress")
                return module and module.run(...)
            end
        end
    elseif context.side == "server" then
        if type(bridge.ensureSql) ~= "function" then
            function bridge:ensureSql(resourceName, options)
                local module = Core.getModule("server", "sql")
                return module and module.ensure(resourceName, options)
            end
        end

        if type(bridge.getVehicleMileage) ~= "function" then
            function bridge:getVehicleMileage()
                return nil, nil, nil
            end
        end
    end

    return bridge
end

function Core.decorateBridge(bridge, context)
    if type(bridge) ~= "table" then
        return bridge
    end

    Core.applyModuleDefaults(bridge, context)

    bridge.__lyre = bridge.__lyre or {}
    bridge.__lyre.resource = context.resource
    bridge.__lyre.side = context.side
    bridge.__lyre.framework = context.framework
    bridge.__lyre.loadedAt = now()

    if type(bridge.safeCall) ~= "function" then
        function bridge:safeCall(methodName, ...)
            return Core.safeBridgeCall(self, methodName, ...)
        end
    end

    if type(bridge.getModule) ~= "function" then
        function bridge:getModule(name)
            return Core.getModule(self.__lyre and self.__lyre.side or context.side, name)
        end
    end

    if type(bridge.requireFunctions) ~= "function" then
        function bridge:requireFunctions(required)
            return Core.validateBridge(self, required, self.__lyre or context)
        end
    end

    if Core.config.wrapBridgeCalls and not bridge.__lyre.wrapped then
        for key, value in pairs(bridge) do
            if type(value) == "function" and not internalBridgeMethods[key] and string.sub(key, 1, 2) ~= "__" then
                local methodName = key
                local originalMethod = value

                bridge[methodName] = function(self, ...)
                    local response = pack(pcall(originalMethod, self, ...))
                    if response[1] then
                        return unpackPacked(response, 2)
                    end

                    local failure = Core.fail("bridge_call_failed", "Bridge method `" .. tostring(methodName) .. "` failed: " .. tostring(response[2]), {
                        method = methodName,
                        resource = context.resource,
                        side = context.side,
                        framework = context.framework,
                    })

                    return false, failure
                end
            end
        end

        bridge.__lyre.wrapped = true
    end

    return bridge
end

local function sortedBridgeNames(registry)
    local names = {}
    for name, bridge in pairs(registry) do
        if type(name) == "string" and type(bridge) == "table" then
            names[#names + 1] = name
        end
    end

    table.sort(names)
    return names
end

local function detectBridge(registry, bridgeName, context)
    local bridge = registry[bridgeName]
    if not bridge then
        return false
    end

    if type(bridge.autoDetect) ~= "function" then
        return false
    end

    local ok, detected = pcall(bridge.autoDetect, bridge)
    if not ok then
        Core.fail("bridge_detect_failed", "Auto detection failed for `" .. tostring(bridgeName) .. "`: " .. tostring(detected), context)
        return false
    end

    return detected == true
end

function Core.setupBridge(side, registry, config, options)
    options = options or {}
    registry = registry or _G.bridge

    local resourceName = options.resource or currentResourceName()
    local context = {
        resource = resourceName,
        side = side or "shared",
    }

    if type(registry) ~= "table" then
        return false, Core.fail("bridge_registry_missing", "No bridge registry is loaded before setup.", context)
    end

    local requestedBridge = options.bridge or (type(config) == "table" and config.bridge) or "auto_detect"

    if type(registry.__lyre) == "table" and type(registry.__lyre.framework) == "string" then
        local requestedName = nil
        if not Core.isAutoBridge(requestedBridge) then
            requestedName = Core.resolveBridgeName(requestedBridge)
        end

        if requestedName and requestedName ~= registry.__lyre.framework then
            return false, Core.fail("invalid_bridge", "Configured bridge `" .. tostring(requestedBridge) .. "` does not match the active bridge `" .. registry.__lyre.framework .. "`.", context)
        end

        context.framework = registry.__lyre.framework
        Core.decorateBridge(registry, context)

        local valid, validationError = Core.validateBridge(registry, options.required, context)
        if not valid then
            return false, validationError
        end

        _G.bridge = registry
        return true, registry
    end

    local selectedBridge = nil
    local selectedName = nil

    if not Core.isAutoBridge(requestedBridge) then
        selectedName = Core.resolveBridgeName(requestedBridge)
        selectedBridge = registry[selectedName]

        if not selectedBridge then
            return false, Core.fail("invalid_bridge", "Configured bridge `" .. tostring(requestedBridge) .. "` is not loaded.", context)
        end
    else
        for _, bridgeName in ipairs(Core.getDetectionOrder(config, options)) do
            local normalizedName = Core.resolveBridgeName(bridgeName)
            if detectBridge(registry, normalizedName, context) then
                selectedName = normalizedName
                selectedBridge = registry[normalizedName]
                break
            end
        end

        if not selectedBridge and options.allowUnorderedFallback ~= false then
            for _, bridgeName in ipairs(sortedBridgeNames(registry)) do
                if detectBridge(registry, bridgeName, context) then
                    selectedName = bridgeName
                    selectedBridge = registry[bridgeName]
                    break
                end
            end
        end
    end

    if not selectedBridge then
        return false, Core.fail("bridge_not_detected", "Unable to detect a compatible bridge.", context)
    end

    context.framework = selectedName

    if not selectedBridge.__lyreInitialized then
        local ok, err = pcall(function()
            if type(selectedBridge.init) == "function" then
                selectedBridge:init()
            end
        end)

        if not ok then
            return false, Core.fail("bridge_init_failed", "Bridge `" .. tostring(selectedName) .. "` failed during init: " .. tostring(err), context)
        end

        selectedBridge.__lyreInitialized = true
    end

    Core.decorateBridge(selectedBridge, context)

    local valid, validationError = Core.validateBridge(selectedBridge, options.required, context)
    if not valid then
        return false, validationError
    end

    _G.bridge = selectedBridge
    Core.log("info", "Bridge ready: " .. tostring(selectedName), context)

    return true, selectedBridge
end

function Core.versionString()
    return Core.version
end
