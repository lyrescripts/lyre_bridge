local Core = LyreBridge
local internals = Core._clientInternals or {}
local currentResourceName = internals.currentResourceName or Core.currentResourceName
local getRequiredFunctions = internals.getRequiredFunctions
function Core.setupClientResourceBridge(config, options)
    options = options or {}
    config = config or _G.Config or {}

    local resourceName = options.resource or currentResourceName()
    Core._clientBridgeSetup = Core._clientBridgeSetup or {}

    if Core._clientBridgeSetup[resourceName] then
        return true, _G.bridge
    end

    Core._clientBridgeSetup[resourceName] = true

    local setupOptions = {}
    for key, value in pairs(options) do
        setupOptions[key] = value
    end

    setupOptions.resource = resourceName
    setupOptions.required = getRequiredFunctions(config, options)

    local success, result = Core.setupBridge("client", _G.bridge, config, setupOptions)
    if not success then
        Core._clientBridgeSetup[resourceName] = nil
        Core.log("error", result and result.message or "Unable to setup the client bridge.", {
            resource = resourceName,
            side = "client",
        })
        return false, result
    end

    return true, result
end
