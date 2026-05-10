local Core = LyreBridge
local internals = Core._internals or {}
local now = internals.now or function()
    return math.floor(os.clock() * 1000)
end
local pack = internals.pack or table.pack or function(...)
    return { n = select("#", ...), ... }
end
local unpackPacked = internals.unpackPacked or function(values, first)
    local unpack = table.unpack or unpack
    return unpack(values, first or 1, values.n or #values)
end
local internalBridgeMethods = internals.internalBridgeMethods or {}
local currentResourceName = internals.currentResourceName or Core.currentResourceName or function()
    return "unknown"
end
local frameworkResources = {
    ESX = "es_extended",
    QBOX = "qbx_core",
    QBCORE = "qb-core",
}

local function getResourceStateNow(resourceName)
    if type(resourceName) ~= "string" or resourceName == "" or type(GetResourceState) ~= "function" then
        return "missing"
    end

    return GetResourceState(resourceName)
end

local function clearFrameworkStateCache()
    if type(Core._stateCache) ~= "table" then
        return
    end

    for _, resourceName in pairs(frameworkResources) do
        Core._stateCache[resourceName] = nil
    end
end

local function waitForAutoDetect(delay)
    delay = tonumber(delay) or 0
    if type(Wait) == "function" then
        Wait(delay)
        return true
    end

    if type(Citizen) == "table" and type(Citizen.Wait) == "function" then
        Citizen.Wait(delay)
        return true
    end

    return false
end

local function frameworkResourceCanStillStart()
    for _, resourceName in pairs(frameworkResources) do
        local state = getResourceStateNow(resourceName)
        if state == "starting" or state == "uninitialized" then
            return true
        end
    end

    return false
end

local function hasActiveFrameworkResource()
    for _, resourceName in pairs(frameworkResources) do
        local state = getResourceStateNow(resourceName)
        if state == "started" or state == "starting" then
            return true
        end
    end

    return false
end

local function requireFrameworkObject(bridge, frameworkName, resourceName, getter)
    if bridge.object ~= nil then
        return bridge.object
    end

    if not Core.isStarted(resourceName, 0) then
        error("Framework resource `" .. resourceName .. "` is not started for `" .. frameworkName .. "`.")
    end

    local ok, object = pcall(getter)
    if not ok then
        error("Unable to load `" .. frameworkName .. "` object from `" .. resourceName .. "`: " .. tostring(object))
    end

    if object == nil then
        error("Framework `" .. frameworkName .. "` from `" .. resourceName .. "` returned nil.")
    end

    bridge.object = object
    return object
end

local defaultBridgeFactories = {
    ESX = function()
        return {
            autoDetect = function()
                return Core.isStarted("es_extended")
            end,

            init = function(self)
                return requireFrameworkObject(self, "ESX", "es_extended", function()
                    return exports["es_extended"]:getSharedObject()
                end)
            end,
        }
    end,

    QBOX = function()
        return {
            autoDetect = function()
                return Core.isStarted("qbx_core")
            end,

            init = function(self)
                return requireFrameworkObject(self, "QBOX", "qbx_core", function()
                    return exports["qbx_core"]
                end)
            end,
        }
    end,

    QBCORE = function()
        return {
            autoDetect = function()
                return Core.isStarted("qb-core")
            end,

            init = function(self)
                return requireFrameworkObject(self, "QBCORE", "qb-core", function()
                    return exports["qb-core"]:GetCoreObject()
                end)
            end,
        }
    end,

    STANDALONE = function()
        return {
            autoDetect = function()
                return not hasActiveFrameworkResource()
            end,

            init = function()
                return true
            end,
        }
    end,

    EXAMPLE = function()
        return {
            autoDetect = function()
                return false
            end,

            init = function()
                return true
            end,
        }
    end,
}

local function registerDefaultBridgeCandidate(registry, name)
    local factory = defaultBridgeFactories[name]
    if type(factory) ~= "function" then
        return
    end

    local defaults = factory()
    if type(registry[name]) == "table" then
        for key, value in pairs(defaults) do
            if registry[name][key] == nil then
                registry[name][key] = value
            end
        end

        registry[name].__lyreDefaultHydrated = true
        return
    end

    defaults.__lyreDefaultCandidate = true
    registry[name] = defaults
end

function Core.registerDefaultBridgeCandidates(side, registry)
    if side ~= "client" and side ~= "server" then
        return registry
    end

    if type(registry) == "table" and type(registry.__lyre) == "table" then
        return registry
    end

    registry = registry or {}
    _G.bridge = registry

    registerDefaultBridgeCandidate(registry, "ESX")
    registerDefaultBridgeCandidate(registry, "QBOX")
    registerDefaultBridgeCandidate(registry, "QBCORE")
    registerDefaultBridgeCandidate(registry, "STANDALONE")
    registerDefaultBridgeCandidate(registry, "EXAMPLE")

    return registry
end

function Core.bridgeCandidate(bridgeName)
    local normalizedName = Core.resolveBridgeName(bridgeName)
    _G.bridge = _G.bridge or {}

    if type(_G.bridge[normalizedName]) ~= "table" then
        _G.bridge[normalizedName] = {}
    end

    _G.bridge[normalizedName].__lyreUserOverridden = true

    return _G.bridge[normalizedName], normalizedName
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

local function rememberActiveBridge(resourceName, side, bridge)
    if type(resourceName) ~= "string" or resourceName == "" or type(side) ~= "string" then
        return
    end

    Core.activeBridges = Core.activeBridges or {}
    Core.activeBridges[resourceName] = Core.activeBridges[resourceName] or {}
    Core.activeBridges[resourceName][side] = bridge
end

function Core.getActiveBridge(resourceName, side)
    if type(resourceName) ~= "string" or resourceName == "" or type(side) ~= "string" then
        return nil
    end

    return Core.activeBridges
        and Core.activeBridges[resourceName]
        and Core.activeBridges[resourceName][side]
        or nil
end

function Core.getActiveBridgeInfo(resourceName, side)
    local activeBridge = Core.getActiveBridge(resourceName, side)
    if type(activeBridge) ~= "table" then
        return nil
    end

    local methods = {}
    for key, value in pairs(activeBridge) do
        if type(key) == "string" and type(value) == "function" and string.sub(key, 1, 2) ~= "__" then
            methods[#methods + 1] = key
        end
    end

    table.sort(methods)

    return {
        resource = activeBridge.__lyre and activeBridge.__lyre.resource or resourceName,
        side = activeBridge.__lyre and activeBridge.__lyre.side or side,
        framework = activeBridge.__lyre and activeBridge.__lyre.framework or nil,
        loadedAt = activeBridge.__lyre and activeBridge.__lyre.loadedAt or nil,
        methods = methods,
    }
end

local function addRequiredMethod(target, seen, methodName)
    if type(methodName) ~= "string" or methodName == "" or seen[methodName] then
        return
    end

    seen[methodName] = true
    target[#target + 1] = methodName
end

local function inferRequiredBridgeMethods(registry, explicitRequired, options)
    local required = {}
    local seen = {}

    if type(explicitRequired) == "table" then
        for _, methodName in ipairs(explicitRequired) do
            addRequiredMethod(required, seen, methodName)
        end
    end

    if options and options.inferRequiredMethods == false then
        return #required > 0 and required or nil
    end

    -- A method is contractual only when every resource adapter declares it.
    -- This avoids spurious failures when one framework gets a custom method
    -- that other frameworks (often STANDALONE) intentionally do not provide.
    local methodPresence = {}
    local resourceCandidates = 0

    for _, candidate in pairs(registry or {}) do
        if type(candidate) == "table"
            and candidate.__lyreDefaultCandidate ~= true
            and candidate.__lyreUserOverridden == true
        then
            resourceCandidates = resourceCandidates + 1
            for methodName, value in pairs(candidate) do
                if type(value) == "function"
                    and not internalBridgeMethods[methodName]
                    and string.sub(methodName, 1, 2) ~= "__"
                then
                    methodPresence[methodName] = (methodPresence[methodName] or 0) + 1
                end
            end
        end
    end

    if resourceCandidates > 0 then
        for methodName, count in pairs(methodPresence) do
            if count == resourceCandidates then
                addRequiredMethod(required, seen, methodName)
            end
        end
    end

    table.sort(required)
    return #required > 0 and required or nil
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
    registry = Core.registerDefaultBridgeCandidates(side, registry)

    local resourceName = options.resource or currentResourceName()
    local context = {
        resource = resourceName,
        side = side or "shared",
    }

    if type(registry) ~= "table" then
        return false, Core.fail("bridge_registry_missing", "No bridge registry is loaded before setup. Check the resource identity file and adapter names under `lyre_bridge/resources/<resource>/bridge`.", context)
    end

    local requestedBridge = options.bridge or (type(config) == "table" and config.bridge) or "auto_detect"
    local requiredMethods = inferRequiredBridgeMethods(registry, options.required, options)

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

        local valid, validationError = Core.validateBridge(registry, requiredMethods, context)
        if not valid then
            return false, validationError
        end

        _G.bridge = registry
        rememberActiveBridge(resourceName, side or "shared", registry)
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
        local attempts = tonumber(options.autoDetectAttempts or Core.config.autoDetectAttempts) or 20
        local delay = tonumber(options.autoDetectDelayMs or Core.config.autoDetectDelayMs) or 250

        for attempt = 1, attempts do
            clearFrameworkStateCache()

            for _, bridgeName in ipairs(Core.getDetectionOrder(config, options)) do
                local normalizedName = Core.resolveBridgeName(bridgeName)
                if detectBridge(registry, normalizedName, context) then
                    selectedName = normalizedName
                    selectedBridge = registry[normalizedName]
                    break
                end
            end

            if selectedBridge or not frameworkResourceCanStillStart() or attempt >= attempts then
                break
            end

            if not waitForAutoDetect(delay) then
                break
            end
        end

        if not selectedBridge and options.allowUnorderedFallback ~= false then
            for attempt = 1, attempts do
                clearFrameworkStateCache()

                for _, bridgeName in ipairs(sortedBridgeNames(registry)) do
                    if detectBridge(registry, bridgeName, context) then
                        selectedName = bridgeName
                        selectedBridge = registry[bridgeName]
                        break
                    end
                end

                if selectedBridge or not frameworkResourceCanStillStart() or attempt >= attempts then
                    break
                end

                if not waitForAutoDetect(delay) then
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

    local valid, validationError = Core.validateBridge(selectedBridge, requiredMethods, context)
    if not valid then
        return false, validationError
    end

    _G.bridge = selectedBridge
    rememberActiveBridge(resourceName, side or "shared", selectedBridge)
    Core.log("debug", "Bridge ready: " .. tostring(selectedName), context)

    return true, selectedBridge
end

function Core.versionString()
    return Core.version
end
