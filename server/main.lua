exports("EnsureResourceSchema", function(resourceName, options)
    return LyreBridge.SQL.ensureResourceSchema(resourceName, options)
end)

exports("SqlQuery", function(query, params)
    return LyreBridge.SQL.query(query, params)
end)

exports("SqlSingle", function(query, params)
    return LyreBridge.SQL.single(query, params)
end)

exports("SqlScalar", function(query, params)
    return LyreBridge.SQL.scalar(query, params)
end)

exports("SqlUpdate", function(query, params)
    return LyreBridge.SQL.update(query, params)
end)

exports("SqlInsert", function(query, params)
    return LyreBridge.SQL.insert(query, params)
end)

exports("SqlTransaction", function(queries, params)
    return LyreBridge.SQL.transaction(queries, params)
end)

exports("SqlReady", function()
    return LyreBridge.SQL.ready()
end)

exports("GetResourceDefinition", function(resourceName)
    return LyreBridge.getResourceDefinition(resourceName)
end)

exports("ListRegisteredResources", function()
    return LyreBridge.listRegisteredResources()
end)

exports("CheckResourceDefinitions", function()
    return LyreBridge.validateResourceDefinitions()
end)

CreateThread(function()
    Wait(0)
    LyreBridge.log("debug", "Core ready.", {
        resource = GetCurrentResourceName(),
        version = LyreBridge.version,
        autoSql = LyreBridge.SQL.config.autoSql,
        sqlStrict = LyreBridge.SQL.config.strict,
    })
end)

local function parseSqlCommandArgs(args)
    local options = {
        force = false,
    }

    for index = 2, #args do
        local value = tostring(args[index] or "")
        local lower = string.lower(value)

        if lower == "force" or lower == "true" or lower == "1" then
            options.force = true
        elseif value ~= "" then
            options.framework = value
        end
    end

    return options
end

RegisterCommand("lyre_bridge_check", function(source)
    if source ~= 0 and not IsPlayerAceAllowed(source, "lyre_bridge.check") then
        return
    end

    local summary = LyreBridge.validateResourceDefinitions()
    local level = summary.ok and "info" or "error"
    LyreBridge.log(level, "Resource registry check completed.", {
        resources = summary.resources,
        bridgeFiles = summary.bridgeFiles,
        sqlFiles = summary.sqlFiles,
        warnings = #summary.warnings,
        errors = #summary.errors,
    })

    for _, issue in ipairs(summary.warnings) do
        LyreBridge.log("warn", issue.code .. ": " .. issue.message, issue.context)
    end

    if not summary.ok then
        for _, issue in ipairs(summary.errors) do
            LyreBridge.log("error", issue.code .. ": " .. issue.message, issue.context)
        end
    end
end, true)

RegisterCommand("lyre_bridge_sql", function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, "lyre_bridge.sql") then
        return
    end

    local resourceName = args[1]
    if not resourceName or resourceName == "" then
        LyreBridge.log("error", "Usage: lyre_bridge_sql <resourceName> [force] [framework]", {
            resource = GetCurrentResourceName(),
        })
        return
    end

    local options = parseSqlCommandArgs(args)
    local result = LyreBridge.SQL.ensureResourceSchema(resourceName, options)

    if result and result.ok then
        LyreBridge.log("info", "SQL command completed for " .. resourceName, {
            resource = resourceName,
            force = options.force,
            framework = options.framework or "auto",
        })
        return
    end

    LyreBridge.log("error", result and result.message or "SQL command failed.", {
        resource = resourceName,
        force = options.force,
        framework = options.framework or "auto",
    })
end, true)
