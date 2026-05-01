if not LyreBridge or not LyreBridge.setupBridge then
    local runtime = LoadResourceFile("lyre_bridge", "imports/shared.lua")
    assert(runtime, "lyre_bridge imports/shared.lua is missing")

    local fn, err = load(runtime, "@lyre_bridge/imports/shared.lua")
    assert(fn, err)
    fn()
end

local Core = LyreBridge

function Core.ensureResourceSql(resourceName, options)
    resourceName = resourceName or GetCurrentResourceName()
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
