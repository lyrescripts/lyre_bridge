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

exports("GetResourceSqlMigrations", function(resourceName)
    return LyreBridge.SQL.getResourceMigrations(resourceName)
end)

exports("GetResourceDefinition", function(resourceName)
    return LyreBridge.getResourceDefinition(resourceName)
end)

exports("GetResourceIdentity", function(resourceName)
    return LyreBridge.getResourceIdentity(resourceName)
end)

exports("GetActiveBridgeInfo", function(resourceName, side)
    return LyreBridge.getActiveBridgeInfo(resourceName, side)
end)

exports("ListRegisteredResources", function()
    return LyreBridge.listRegisteredResources()
end)

exports("CheckResourceDefinitions", function()
    return LyreBridge.validateResourceDefinitions()
end)

CreateThread(function()
    Wait(0)

    if LyreBridge.config.checkForUpdates and type(LyreBridge.performVersionCheck) == "function" then
        LyreBridge.performVersionCheck()
    end

    LyreBridge.log("debug", "Core ready.", {
        resource = GetCurrentResourceName(),
        version = LyreBridge.version,
        autoSql = LyreBridge.SQL.config.autoSql,
        autoSqlEvents = LyreBridge.SQL.config.autoSqlEvents,
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
        elseif lower == "events" or lower == "allow_events" or lower == "allowevents" then
            options.allowEvents = true
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

RegisterCommand("lyre_bridge_sql_status", function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, "lyre_bridge.sql") then
        return
    end

    local resourceName = args[1]
    if not resourceName or resourceName == "" then
        LyreBridge.log("error", "Usage: lyre_bridge_sql_status <resourceName>", {
            resource = GetCurrentResourceName(),
        })
        return
    end

    local result = LyreBridge.SQL.getResourceMigrations(resourceName)
    if not result or result.ok == false then
        LyreBridge.log("error", result and result.message or "Unable to read SQL migration status.", {
            resource = resourceName,
            code = result and result.code,
        })
        return
    end

    local rows = result.data or {}
    local counts = { applied = 0, warning = 0, failed = 0, other = 0 }

    for _, row in ipairs(rows) do
        if row.status == "applied" then
            counts.applied = counts.applied + 1
        elseif row.status == "warning" then
            counts.warning = counts.warning + 1
        elseif row.status == "failed" then
            counts.failed = counts.failed + 1
        else
            counts.other = counts.other + 1
        end
    end

    local summaryLevel = "info"
    if counts.failed > 0 then
        summaryLevel = "error"
    elseif counts.warning > 0 or counts.other > 0 then
        summaryLevel = "warn"
    end

    LyreBridge.log(summaryLevel, "SQL migration status.", {
        resource = resourceName,
        migrations = #rows,
        applied = counts.applied,
        warning = counts.warning,
        failed = counts.failed,
        other = counts.other,
    })

    for _, row in ipairs(rows) do
        local rowLevel = "info"
        if row.status == "failed" then
            rowLevel = "error"
        elseif row.status ~= "applied" then
            rowLevel = "warn"
        end

        LyreBridge.log(rowLevel, "SQL migration.", {
            resource = resourceName,
            id = row.id,
            status = row.status,
            checksum = row.checksum,
            error = row.error,
        })
    end
end, true)

local function formatFrameworkSql(identity)
    local parts = {}

    for _, item in ipairs(identity.sql and identity.sql.frameworkFiles or {}) do
        parts[#parts + 1] = tostring(item.framework) .. ":" .. tostring(item.files)
    end

    return #parts > 0 and table.concat(parts, ",") or "none"
end

local function logIdentityDetails(identity)
    for _, file in ipairs(identity.bridge and identity.bridge.client or {}) do
        LyreBridge.log("info", "Resource client bridge file.", {
            resource = identity.resource,
            path = file,
        })
    end

    for _, file in ipairs(identity.bridge and identity.bridge.server or {}) do
        LyreBridge.log("info", "Resource server bridge file.", {
            resource = identity.resource,
            path = file,
        })
    end

    for _, entry in ipairs(identity.sql and identity.sql.files or {}) do
        LyreBridge.log("info", "Resource common SQL file.", {
            resource = identity.resource,
            id = entry.id,
            path = entry.path,
            required = entry.required,
        })
    end

    for framework, entries in pairs(identity.sql and identity.sql.frameworks or {}) do
        for _, entry in ipairs(entries) do
            LyreBridge.log("info", "Resource framework SQL file.", {
                resource = identity.resource,
                framework = framework,
                id = entry.id,
                path = entry.path,
                required = entry.required,
            })
        end
    end
end

RegisterCommand("lyre_bridge_resource", function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, "lyre_bridge.check") then
        return
    end

    local resourceName = args[1]
    if not resourceName or resourceName == "" then
        local resources = LyreBridge.listRegisteredResources()
        LyreBridge.log("info", "Registered resources: " .. table.concat(resources, ", "), {
            count = #resources,
        })
        return
    end

    local identity = LyreBridge.getResourceIdentity(resourceName)
    if not identity then
        LyreBridge.log("error", "Resource is not registered.", {
            resource = resourceName,
            hint = "Check lyre_bridge/resources/" .. resourceName .. "/resource.lua",
        })
        return
    end

    LyreBridge.log("info", "Resource identity.", {
        resource = identity.resource,
        path = identity.path,
        clientBridgeFiles = identity.bridge and identity.bridge.clientFiles or 0,
        serverBridgeFiles = identity.bridge and identity.bridge.serverFiles or 0,
        defaultBridgeCandidates = identity.bridge and table.concat(identity.bridge.defaultCandidates or {}, ",") or "none",
        sqlFiles = identity.sql and identity.sql.commonFiles or 0,
        frameworkSql = formatFrameworkSql(identity),
    })

    local verbose = tostring(args[2] or "") == "verbose" or tostring(args[2] or "") == "details"
    if verbose then
        logIdentityDetails(identity)
    end
end, true)
