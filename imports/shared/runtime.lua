local Core = LyreBridge
local currentResourceName = Core.currentResourceName or function()
    return "unknown"
end
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

Core._internals.currentResourceName = currentResourceName
Core._internals.now = now
Core._internals.pack = pack
Core._internals.unpackPacked = unpackPacked
Core._internals.internalBridgeMethods = internalBridgeMethods
