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
    Core.log("debug", "Bridge ready: " .. tostring(selectedName), context)

    return true, selectedBridge
end

function Core.versionString()
    return Core.version
end
