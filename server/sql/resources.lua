local Core = LyreBridge
local SQL = Core.SQL
local Private = SQL._private
local Migrations = Private.migrations
local Schema = Private.schema
local Statements = Private.statements

local function applyLicenseSeeds(resourceName, summary)
    local compat = Core.SQL_COMPAT or {}
    local seeds = compat.licenseSeeds and compat.licenseSeeds[resourceName]

    if type(seeds) ~= "table" or #seeds == 0 then
        return true
    end

    if not Schema.tableExists("licenses") then
        summary.warnings[#summary.warnings + 1] = "licenses_table_missing"
        Core.log("warn", "Skipped license seed because `licenses` table does not exist.", {
            resource = resourceName,
            operation = "license_seed",
        })
        return true
    end

    for _, seed in ipairs(seeds) do
        local ok, response = Private.queryAwait("update", "INSERT IGNORE INTO `licenses` (`type`, `label`) VALUES (?, ?)", {
            seed.type,
            seed.label,
        }, { resource = resourceName, operation = "license_seed", license = seed.type })

        if not ok then
            summary.errors[#summary.errors + 1] = response
            if SQL.config.strict then
                return false, response
            end
        else
            summary.applied = summary.applied + 1
        end
    end

    return true
end

local function pathToMigrationId(path)
    local id = tostring(path or "sql")
    id = id:gsub("%.sql$", "")
    id = id:gsub("[/\\]+", "_")
    id = id:gsub("[^%w_]+", "_")
    id = id:gsub("^_+", ""):gsub("_+$", "")

    if id == "sql_import" or id == "import" then
        return "import_sql"
    end

    return id ~= "" and id or "sql"
end

local function cloneSqlEntry(entry)
    if type(entry) == "string" then
        return {
            path = entry,
        }
    end

    if type(entry) ~= "table" then
        return nil
    end

    local cloned = {}
    for key, value in pairs(entry) do
        cloned[key] = value
    end

    return cloned
end

local function addSqlEntries(target, entries)
    if type(entries) ~= "table" then
        return
    end

    for index, entry in ipairs(entries) do
        local cloned = cloneSqlEntry(entry)
        if cloned and type(cloned.path) == "string" and cloned.path ~= "" then
            cloned.id = cloned.id or pathToMigrationId(cloned.path)
            cloned.order = cloned.order or index
            target[#target + 1] = cloned
        end
    end
end

local function resolveSqlFramework(options)
    options = options or {}

    local requested = options.framework or options.bridge
    if type(requested) == "string" and requested ~= "" and not Core.isAutoBridge(requested) then
        return Core.resolveBridgeName(requested)
    end

    for _, frameworkName in ipairs(Core.getDetectionOrder(nil, options)) do
        local normalized = Core.resolveBridgeName(frameworkName)

        if normalized == "ESX" and Core.isStarted("es_extended") then
            return normalized
        elseif normalized == "QBOX" and Core.isStarted("qbx_core") then
            return normalized
        elseif normalized == "QBCORE" and Core.isStarted("qb-core") then
            return normalized
        elseif normalized == "STANDALONE" then
            return normalized
        end
    end

    return nil
end

local function resolveResourceSql(resourceName, options)
    local definition = Core.getResourceDefinition and Core.getResourceDefinition(resourceName)
    local entries = {}
    local framework = resolveSqlFramework(options)

    if definition and type(definition.sql) == "table" then
        addSqlEntries(entries, definition.sql.files)

        local frameworkFiles = definition.sql.frameworkFiles
        if framework and type(frameworkFiles) == "table" then
            addSqlEntries(entries, frameworkFiles[framework])
            addSqlEntries(entries, frameworkFiles[string.lower(framework)])
        end

        table.sort(entries, function(left, right)
            return (left.order or 0) < (right.order or 0)
        end)

        return entries, framework, definition
    end

    local importFile = options.importFile or SQL.config.importFile
    addSqlEntries(entries, {
        {
            id = "import_sql",
            path = importFile,
            legacy = true,
            optional = true,
        },
    })

    return entries, framework, nil
end

local function resolveSqlLoadTarget(resourceName, entry)
    if entry.legacy then
        return resourceName, entry.path
    end

    if type(entry.resource) == "string" and entry.resource ~= "" then
        return entry.resource, entry.path
    end

    if entry.absolute then
        return "lyre_bridge", entry.path
    end

    if entry.path:sub(1, #"resources/") == "resources/" then
        return "lyre_bridge", entry.path
    end

    return "lyre_bridge", ("resources/%s/%s"):format(resourceName, entry.path)
end

local function hasRequiredTables(entry, fileSummary, summary, context)
    if type(entry.requiresTables) ~= "table" then
        return true
    end

    for _, tableName in ipairs(entry.requiresTables) do
        if type(tableName) == "string" and tableName ~= "" and not Schema.tableExists(tableName) then
            local warning = "missing_required_table:" .. tableName
            fileSummary.skipped = true
            fileSummary.reason = warning
            summary.skipped = summary.skipped + 1
            summary.warnings[#summary.warnings + 1] = warning
            Core.log("warn", "Skipped optional SQL file because a required table is missing.", {
                resource = context.resource,
                file = context.file,
                table = tableName,
            })
            return false
        end
    end

    return true
end

local function applySqlEntry(resourceName, entry, options, summary)
    local loadResource, loadPath = resolveSqlLoadTarget(resourceName, entry)
    local fileSummary = {
        id = entry.id,
        path = loadPath,
        source = loadResource,
        applied = 0,
        skipped = 0,
        errors = 0,
    }

    summary.files[#summary.files + 1] = fileSummary

    local context = {
        resource = resourceName,
        operation = "ensure_schema",
        file = loadPath,
    }

    local sql = LoadResourceFile(loadResource, loadPath)
    if type(sql) ~= "string" or Private.trim(sql) == "" then
        if entry.required then
            return false, Core.fail("sql_file_missing", "Registered SQL file is missing or empty.", context)
        end

        fileSummary.skipped = true
        fileSummary.reason = "sql_file_missing"
        summary.skipped = summary.skipped + 1
        return true
    end

    if not hasRequiredTables(entry, fileSummary, summary, context) then
        return true
    end

    local hash = Statements.checksum(sql)
    local migrationId = ("%s:%s:%s"):format(resourceName, entry.id or "sql", hash)
    fileSummary.migration = migrationId
    fileSummary.checksum = hash

    local exists, existingMigration = Migrations.exists(migrationId)
    if existingMigration and existingMigration.ok == false then
        return false, existingMigration
    end

    if exists and not options.force and existingMigration.status == "applied" then
        fileSummary.skipped = true
        fileSummary.reason = "already_applied"
        summary.skipped = summary.skipped + 1
        return true
    end

    if exists and not options.force then
        Core.log("warn", "Retrying SQL migration that did not finish cleanly.", {
            resource = resourceName,
            migration = migrationId,
            status = existingMigration.status or "unknown",
        })
    end

    local statements = Statements.split(sql)
    local compat = Core.SQL_COMPAT or {}
    local skipPrepared = compat.skipPreparedLicenseBlocks and compat.skipPreparedLicenseBlocks[resourceName]

    for index, rawStatement in ipairs(statements) do
        local statement = Private.trim(rawStatement)
        local statementContext = {
            resource = resourceName,
            migration = migrationId,
            statement = index,
            file = loadPath,
        }

        if skipPrepared and Statements.isPreparedLicenseStatement(statement) then
            fileSummary.skipped = fileSummary.skipped + 1
            summary.skipped = summary.skipped + 1
        elseif Statements.isEventStatement(statement) and not SQL.config.autoSqlEvents and not options.allowEvents then
            fileSummary.skipped = fileSummary.skipped + 1
            summary.skipped = summary.skipped + 1
            summary.warnings[#summary.warnings + 1] = "mysql_event_sql_skipped"
            Core.log("warn", "Skipped MySQL event SQL because lyre_bridge:autoSqlEvents is disabled.", statementContext)
        else
            statement = Statements.normalize(statement)

            local statementOk, response = Statements.execute(statement, statementContext)
            if statementOk then
                fileSummary.applied = fileSummary.applied + 1
                summary.applied = summary.applied + 1
            else
                fileSummary.errors = fileSummary.errors + 1
                summary.errors[#summary.errors + 1] = response
                Core.log("error", "SQL statement failed: " .. tostring(response and response.message or response), statementContext)

                if SQL.config.strict or options.strict then
                    Migrations.mark(migrationId, resourceName, hash, "failed", response and response.message or "unknown")
                    return false, response
                end
            end
        end
    end

    local marked, markError = Migrations.mark(migrationId, resourceName, hash, fileSummary.errors > 0 and "warning" or "applied", fileSummary.errors > 0 and "completed_with_warnings" or nil)
    if not marked then
        return false, markError
    end

    return true
end

function SQL.ensureResourceSchema(resourceName, options)
    options = options or {}
    resourceName = resourceName or GetCurrentResourceName()

    local context = {
        resource = resourceName,
        operation = "ensure_schema",
    }

    if not SQL.config.autoSql and not options.force then
        return Private.result(true, { skipped = true, reason = "auto_sql_disabled" }, nil, nil, context)
    end

    local entries, framework, definition = resolveResourceSql(resourceName, options)
    if #entries == 0 then
        if definition and definition.sql and definition.sql.required == true then
            return Core.fail("resource_sql_missing", "Resource requires SQL, but no SQL files were discovered or declared.", context)
        end

        return Private.result(true, {
            skipped = true,
            reason = "no_resource_sql",
            resource = resourceName,
            source = definition and "lyre_bridge" or "legacy",
        }, nil, nil, context)
    end

    if not SQL.ready() then
        return Core.fail("mysql_not_ready", "oxmysql is not ready; cannot prepare SQL.", context)
    end

    local ok, migrationTableError = Migrations.ensureTable()
    if not ok then
        return migrationTableError
    end

    local summary = {
        resource = resourceName,
        source = definition and "lyre_bridge" or "legacy",
        framework = framework,
        applied = 0,
        skipped = 0,
        files = {},
        warnings = {},
        errors = {},
    }

    for _, entry in ipairs(entries) do
        local entryOk, entryError = applySqlEntry(resourceName, entry, options, summary)
        if not entryOk then
            return entryError
        end
    end

    local licenseOk, licenseError = applyLicenseSeeds(resourceName, summary)
    if not licenseOk then
        return licenseError
    end

    Core.log(#summary.errors > 0 and "warn" or "debug", "SQL schema prepared.", {
        resource = resourceName,
        framework = framework or "none",
        applied = summary.applied,
        skipped = summary.skipped,
        errors = #summary.errors,
    })

    return Private.result(true, summary, nil, nil, context)
end
