local Core = LyreBridge
local internals = Core._serverInternals or {}
local currentResourceName = internals.currentResourceName or Core.currentResourceName
local resourceSqlStrict = internals.resourceSqlStrict
local getRequiredFunctions = internals.getRequiredFunctions
function Core.ensureResourceSql(resourceName, options)
    resourceName = resourceName or currentResourceName()
    options = options or {}

    if not Core.isStarted("lyre_bridge") then
        return false, Core.fail("lyre_bridge_not_started", "lyre_bridge must be started before SQL can be prepared.", {
            resource = resourceName,
            side = "server",
        })
    end

    local ok, result = pcall(function()
        return exports["lyre_bridge"]:EnsureResourceSchema(resourceName, options)
    end)

    if not ok then
        return false, Core.fail("sql_prepare_export_failed", tostring(result), {
            resource = resourceName,
            side = "server",
        })
    end

    if type(result) == "table" and result.ok == false then
        Core.log("error", result.message or "SQL preparation failed.", {
            resource = resourceName,
            side = "server",
            code = result.code,
        })
        return false, result
    end

    return true, result
end

function Core.prepareResourceSql(resourceName, config, options)
    options = options or {}
    config = config or _G.Config or {}
    resourceName = resourceName or options.resource or currentResourceName()

    local sqlOptions = {}
    if type(options.sqlOptions) == "table" then
        for key, value in pairs(options.sqlOptions) do
            sqlOptions[key] = value
        end
    end

    sqlOptions.strict = resourceSqlStrict(resourceName, sqlOptions.strict == true or options.strict == true)
    sqlOptions.framework = options.framework or sqlOptions.framework
    sqlOptions.bridge = options.bridge or sqlOptions.bridge or (type(config) == "table" and config.bridge)

    return Core.ensureResourceSql(resourceName, sqlOptions)
end

function Core.setupServerResourceBridge(config, options)
    options = options or {}
    config = config or _G.Config or {}

    local resourceName = options.resource or currentResourceName()
    Core._serverBridgeSetup = Core._serverBridgeSetup or {}

    if Core._serverBridgeSetup[resourceName] then
        return true, Core.getActiveBridge(resourceName, "server") or _G.bridge
    end

    local loaded, loadError = Core.loadResourceBridgeFiles("server", resourceName, options)
    if not loaded then
        Core.log("error", loadError and loadError.message or "Unable to load server bridge files.", {
            resource = resourceName,
            side = "server",
        })
        return false, loadError
    end

    Core._serverBridgeSetup[resourceName] = true

    local setupOptions = {}
    for key, value in pairs(options) do
        setupOptions[key] = value
    end

    setupOptions.resource = resourceName
    setupOptions.required = getRequiredFunctions(config, options)

    local success, result = Core.setupBridge("server", _G.bridge, config, setupOptions)
    if not success then
        Core._serverBridgeSetup[resourceName] = nil
        Core.log("error", result and result.message or "Unable to setup the server bridge.", {
            resource = resourceName,
            side = "server",
        })
        return false, result
    end

    local sqlOptions = {}
    for key, value in pairs(options) do
        sqlOptions[key] = value
    end

    sqlOptions.framework = result and result.__lyre and result.__lyre.framework or sqlOptions.framework

    local sqlSuccess, sqlResult = Core.prepareResourceSql(resourceName, config, sqlOptions)
    if not sqlSuccess then
        Core._serverBridgeSetup[resourceName] = nil
        Core.log("error", sqlResult and sqlResult.message or "Automatic SQL preparation failed.", {
            resource = resourceName,
            side = "server",
            framework = sqlOptions.framework or "unknown",
        })
        return false, sqlResult
    end

    return true, result
end
