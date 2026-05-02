if not LyreBridge or not LyreBridge.setupBridge then
    local runtime = LoadResourceFile("lyre_bridge", "imports/shared.lua")
    assert(runtime, "lyre_bridge imports/shared.lua is missing")

    local fn, err = load(runtime, "@lyre_bridge/imports/shared.lua")
    assert(fn, err)
    fn()
end

local Core = LyreBridge

local function currentResourceName()
    if type(GetCurrentResourceName) == "function" then
        return GetCurrentResourceName()
    end

    return "unknown"
end

local function readBoolConvar(name, default)
    if type(GetConvar) ~= "function" then
        return default
    end

    local sentinel = "__lyre_bridge_unset__"
    local value = GetConvar(name, sentinel)
    if value == sentinel or value == "" then
        return default
    end

    value = string.lower(tostring(value))
    return value == "true" or value == "1" or value == "yes" or value == "on"
end

local function resourceSqlStrict(resourceName, default)
    local names = {
        "lyre_bridge:" .. resourceName .. ":sqlStrict",
        resourceName .. ":sqlStrict",
    }

    local value = default
    for _, name in ipairs(names) do
        value = readBoolConvar(name, value)
    end

    return value
end

local function getRequiredFunctions(config, options)
    if type(options.required) == "table" then
        return options.required
    end

    if type(config) == "table" then
        return config.bridgeRequiredServerFunctions
    end

    return nil
end

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
    sqlOptions.bridge = options.bridge or sqlOptions.bridge or (type(config) == "table" and config.bridge)

    return Core.ensureResourceSql(resourceName, sqlOptions)
end

function Core.setupServerResourceBridge(config, options)
    options = options or {}
    config = config or _G.Config or {}

    local resourceName = options.resource or currentResourceName()
    Core._serverBridgeSetup = Core._serverBridgeSetup or {}

    if Core._serverBridgeSetup[resourceName] then
        return true, _G.bridge
    end

    Core._serverBridgeSetup[resourceName] = true

    local sqlSuccess, sqlResult = Core.prepareResourceSql(resourceName, config, options)
    if not sqlSuccess then
        Core._serverBridgeSetup[resourceName] = nil
        Core.log("error", sqlResult and sqlResult.message or "Automatic SQL preparation failed.", {
            resource = resourceName,
            side = "server",
        })
        return false, sqlResult
    end

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

    return true, result
end

Core.registerModule("server", "sql", function()
    local module = {}

    function module.ensure(resourceName, options)
        return Core.ensureResourceSql(resourceName, options)
    end

    function module.query(query, params)
        return exports["lyre_bridge"]:SqlQuery(query, params)
    end

    function module.single(query, params)
        return exports["lyre_bridge"]:SqlSingle(query, params)
    end

    function module.scalar(query, params)
        return exports["lyre_bridge"]:SqlScalar(query, params)
    end

    function module.update(query, params)
        return exports["lyre_bridge"]:SqlUpdate(query, params)
    end

    function module.insert(query, params)
        return exports["lyre_bridge"]:SqlInsert(query, params)
    end

    return module
end)

Core.registerModule("server", "framework", function()
    local module = {}

    function module.getESX()
        if not Core.isStarted("es_extended") then
            return nil, "es_extended_not_started"
        end

        local ok, object = pcall(function()
            return exports["es_extended"]:getSharedObject()
        end)

        if not ok then
            return nil, object
        end

        return object
    end

    function module.getQBCore()
        if not Core.isStarted("qb-core") then
            return nil, "qb_core_not_started"
        end

        local ok, object = pcall(function()
            return exports["qb-core"]:GetCoreObject()
        end)

        if not ok then
            return nil, object
        end

        return object
    end

    function module.getQBox()
        if not Core.isStarted("qbx_core") then
            return nil, "qbx_core_not_started"
        end

        return exports["qbx_core"]
    end

    return module
end)
