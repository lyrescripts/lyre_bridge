LyreBridge = LyreBridge or {}

local Core = LyreBridge
local SQL = Core.SQL or {}

Core.SQL = SQL

SQL.config = SQL.config or {
    autoSql = true,
    strict = false,
    migrationTable = "lyre_bridge_migrations",
    importFile = "import.sql",
}

local function boolConvar(name, default)
    if type(GetConvar) ~= "function" then
        return default
    end

    local value = string.lower(tostring(GetConvar(name, default and "true" or "false")))
    return value == "true" or value == "1" or value == "yes" or value == "on"
end

SQL.config.autoSql = boolConvar("lyre_bridge:autoSql", SQL.config.autoSql)
SQL.config.strict = boolConvar("lyre_bridge:sqlStrict", SQL.config.strict)

local function result(ok, data, code, message, context)
    if ok then
        return {
            ok = true,
            data = data,
            context = context,
        }
    end

    return Core.fail(code, message, context)
end

local function checksum(text)
    local hash = 7

    for index = 1, #text do
        hash = (hash * 31 + string.byte(text, index)) % 4294967291
    end

    return ("%08x"):format(hash)
end

local function trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function queryAwait(method, query, params, context)
    if not MySQL or not MySQL[method] or not MySQL[method].await then
        return false, Core.fail("mysql_method_missing", "MySQL." .. method .. ".await is not available.", context)
    end

    local ok, response = pcall(function()
        return MySQL[method].await(query, params or {})
    end)

    if not ok then
        return false, Core.fail("mysql_query_failed", tostring(response), context)
    end

    return true, response
end

function SQL.ready()
    return MySQL ~= nil and MySQL.query ~= nil and MySQL.query.await ~= nil
end

function SQL.query(query, params)
    local ok, response = queryAwait("query", query, params, { operation = "query" })
    if not ok then
        return response
    end

    return result(true, response)
end

function SQL.single(query, params)
    local ok, response = queryAwait("single", query, params, { operation = "single" })
    if not ok then
        return response
    end

    return result(true, response)
end

function SQL.scalar(query, params)
    local ok, response = queryAwait("scalar", query, params, { operation = "scalar" })
    if not ok then
        return response
    end

    return result(true, response)
end

function SQL.update(query, params)
    local ok, response = queryAwait("update", query, params, { operation = "update" })
    if not ok then
        return response
    end

    return result(true, response)
end

function SQL.insert(query, params)
    local ok, response = queryAwait("insert", query, params, { operation = "insert" })
    if not ok then
        return response
    end

    return result(true, response)
end

function SQL.transaction(queries, params)
    if not MySQL or not MySQL.transaction or not MySQL.transaction.await then
        return Core.fail("mysql_transaction_missing", "MySQL.transaction.await is not available.")
    end

    local ok, response = pcall(function()
        return MySQL.transaction.await(queries, params or {})
    end)

    if not ok then
        return Core.fail("mysql_transaction_failed", tostring(response))
    end

    return result(true, response)
end

local function splitStatements(sql)
    local statements = {}
    local buffer = {}
    local quote = nil
    local index = 1

    while index <= #sql do
        local char = sql:sub(index, index)
        local nextChar = sql:sub(index + 1, index + 1)

        if quote then
            buffer[#buffer + 1] = char

            if char == "\\" and quote ~= "`" and nextChar ~= "" then
                index = index + 1
                buffer[#buffer + 1] = sql:sub(index, index)
            elseif char == quote then
                if quote ~= "`" and nextChar == quote then
                    index = index + 1
                    buffer[#buffer + 1] = sql:sub(index, index)
                else
                    quote = nil
                end
            end
        elseif char == "-" and nextChar == "-" then
            while index <= #sql and sql:sub(index, index) ~= "\n" do
                index = index + 1
            end
        elseif char == "#" then
            while index <= #sql and sql:sub(index, index) ~= "\n" do
                index = index + 1
            end
        elseif char == "/" and nextChar == "*" then
            index = index + 2
            while index <= #sql and not (sql:sub(index, index) == "*" and sql:sub(index + 1, index + 1) == "/") do
                index = index + 1
            end
            index = index + 1
        else
            if char == "'" or char == '"' or char == "`" then
                quote = char
            end

            if char == ";" and not quote then
                local statement = trim(table.concat(buffer))
                if statement ~= "" then
                    statements[#statements + 1] = statement
                end
                buffer = {}
            else
                buffer[#buffer + 1] = char
            end
        end

        index = index + 1
    end

    local tail = trim(table.concat(buffer))
    if tail ~= "" then
        statements[#statements + 1] = tail
    end

    return statements
end

local function keywordPattern(word)
    local pattern = {}

    for index = 1, #word do
        local char = word:sub(index, index)
        pattern[#pattern + 1] = "[" .. string.lower(char) .. string.upper(char) .. "]"
    end

    return table.concat(pattern)
end

local CREATE_TABLE_PATTERN = "^" .. keywordPattern("CREATE") .. "%s+" .. keywordPattern("TABLE") .. "%s+"
local CREATE_TABLE_IF_NOT_EXISTS_PATTERN = CREATE_TABLE_PATTERN
    .. keywordPattern("IF") .. "%s+"
    .. keywordPattern("NOT") .. "%s+"
    .. keywordPattern("EXISTS") .. "%s+"
local INSERT_INTO_PATTERN = "^" .. keywordPattern("INSERT") .. "%s+" .. keywordPattern("INTO") .. "%s+"
local INSERT_IGNORE_INTO_PATTERN = "^" .. keywordPattern("INSERT") .. "%s+" .. keywordPattern("IGNORE") .. "%s+" .. keywordPattern("INTO") .. "%s+"
local ALTER_TABLE_ADD_COLUMN_IF_NOT_EXISTS_BACKTICK_PATTERN = "^"
    .. keywordPattern("ALTER") .. "%s+"
    .. keywordPattern("TABLE") .. "%s+"
    .. "`([^`]+)`%s+"
    .. keywordPattern("ADD") .. "%s+"
    .. keywordPattern("COLUMN") .. "%s+"
    .. keywordPattern("IF") .. "%s+"
    .. keywordPattern("NOT") .. "%s+"
    .. keywordPattern("EXISTS") .. "%s+"
    .. "`([^`]+)`%s+"
    .. "(.+)$"
local ALTER_TABLE_ADD_COLUMN_IF_NOT_EXISTS_PLAIN_PATTERN = "^"
    .. keywordPattern("ALTER") .. "%s+"
    .. keywordPattern("TABLE") .. "%s+"
    .. "([%w_%-]+)%s+"
    .. keywordPattern("ADD") .. "%s+"
    .. keywordPattern("COLUMN") .. "%s+"
    .. keywordPattern("IF") .. "%s+"
    .. keywordPattern("NOT") .. "%s+"
    .. keywordPattern("EXISTS") .. "%s+"
    .. "([%w_%-]+)%s+"
    .. "(.+)$"
local ALTER_TABLE_BACKTICK_PATTERN = "^"
    .. keywordPattern("ALTER") .. "%s+"
    .. keywordPattern("TABLE") .. "%s+"
    .. "`([^`]+)`%s+"
    .. "([%s%S]+)$"
local ALTER_TABLE_PLAIN_PATTERN = "^"
    .. keywordPattern("ALTER") .. "%s+"
    .. keywordPattern("TABLE") .. "%s+"
    .. "([%w_%-]+)%s+"
    .. "([%s%S]+)$"
local ADD_COLUMN_IF_NOT_EXISTS_BACKTICK_PATTERN = "^%s*"
    .. keywordPattern("ADD") .. "%s+"
    .. keywordPattern("COLUMN") .. "%s+"
    .. keywordPattern("IF") .. "%s+"
    .. keywordPattern("NOT") .. "%s+"
    .. keywordPattern("EXISTS") .. "%s+"
    .. "`([^`]+)`%s+"
    .. "([%s%S]+)$"
local ADD_COLUMN_IF_NOT_EXISTS_PLAIN_PATTERN = "^%s*"
    .. keywordPattern("ADD") .. "%s+"
    .. keywordPattern("COLUMN") .. "%s+"
    .. keywordPattern("IF") .. "%s+"
    .. keywordPattern("NOT") .. "%s+"
    .. keywordPattern("EXISTS") .. "%s+"
    .. "([%w_%-]+)%s+"
    .. "([%s%S]+)$"
local ADD_INDEX_IF_NOT_EXISTS_BACKTICK_PATTERN = "^%s*"
    .. keywordPattern("ADD") .. "%s+"
    .. keywordPattern("INDEX") .. "%s+"
    .. keywordPattern("IF") .. "%s+"
    .. keywordPattern("NOT") .. "%s+"
    .. keywordPattern("EXISTS") .. "%s+"
    .. "`([^`]+)`%s+"
    .. "([%s%S]+)$"
local ADD_INDEX_IF_NOT_EXISTS_PLAIN_PATTERN = "^%s*"
    .. keywordPattern("ADD") .. "%s+"
    .. keywordPattern("INDEX") .. "%s+"
    .. keywordPattern("IF") .. "%s+"
    .. keywordPattern("NOT") .. "%s+"
    .. keywordPattern("EXISTS") .. "%s+"
    .. "([%w_%-]+)%s+"
    .. "([%s%S]+)$"
local ADD_KEY_IF_NOT_EXISTS_BACKTICK_PATTERN = "^%s*"
    .. keywordPattern("ADD") .. "%s+"
    .. keywordPattern("KEY") .. "%s+"
    .. keywordPattern("IF") .. "%s+"
    .. keywordPattern("NOT") .. "%s+"
    .. keywordPattern("EXISTS") .. "%s+"
    .. "`([^`]+)`%s+"
    .. "([%s%S]+)$"
local ADD_KEY_IF_NOT_EXISTS_PLAIN_PATTERN = "^%s*"
    .. keywordPattern("ADD") .. "%s+"
    .. keywordPattern("KEY") .. "%s+"
    .. keywordPattern("IF") .. "%s+"
    .. keywordPattern("NOT") .. "%s+"
    .. keywordPattern("EXISTS") .. "%s+"
    .. "([%w_%-]+)%s+"
    .. "([%s%S]+)$"

local function normalizeCreateTable(statement)
    if statement:match(CREATE_TABLE_IF_NOT_EXISTS_PATTERN) then
        return statement
    end

    return statement:gsub(CREATE_TABLE_PATTERN, "CREATE TABLE IF NOT EXISTS ", 1)
end

local function normalizeInsert(statement)
    if statement:match(INSERT_IGNORE_INTO_PATTERN) then
        return statement
    end

    return statement:gsub(INSERT_INTO_PATTERN, "INSERT IGNORE INTO ", 1)
end

local function normalizeStatement(statement)
    local upper = string.upper(statement)

    if upper:match("^CREATE%s+TABLE%s+") then
        return normalizeCreateTable(statement)
    end

    if upper:match("^INSERT%s+INTO%s+") then
        return normalizeInsert(statement)
    end

    return statement
end

local function isPreparedLicenseStatement(statement)
    local upper = string.upper(statement)
    return upper:match("^SET%s+@TABLE_EXISTS")
        or upper:match("^SET%s+@INSERT_SQL")
        or upper:match("^PREPARE%s+STMT")
        or upper:match("^EXECUTE%s+STMT")
        or upper:match("^DEALLOCATE%s+PREPARE%s+STMT")
end

local function isIgnorableSqlError(message)
    message = string.lower(tostring(message or ""))

    return message:find("already exists", 1, true)
        or message:find("duplicate column", 1, true)
        or message:find("duplicate key name", 1, true)
        or message:find("duplicate entry", 1, true)
        or message:find("check that column/key exists", 1, true)
end

local function ensureMigrationTable()
    local query = ([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` VARCHAR(190) NOT NULL,
            `resource` VARCHAR(100) NOT NULL,
            `checksum` VARCHAR(64) NOT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'applied',
            `error` LONGTEXT DEFAULT NULL,
            `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_resource` (`resource`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]]):format(SQL.config.migrationTable)

    local ok, response = queryAwait("query", query, {}, { operation = "ensure_migration_table" })
    return ok, response
end

local function migrationExists(migrationId)
    local ok, response = queryAwait("single", ("SELECT `id`, `checksum`, `status` FROM `%s` WHERE `id` = ? LIMIT 1"):format(SQL.config.migrationTable), {
        migrationId,
    }, { operation = "migration_exists", migration = migrationId })

    if not ok then
        return false, response
    end

    return response ~= nil, response
end

local function markMigration(migrationId, resourceName, hash, status, errorText)
    local query = ([[
        INSERT INTO `%s` (`id`, `resource`, `checksum`, `status`, `error`)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `checksum` = VALUES(`checksum`),
            `status` = VALUES(`status`),
            `error` = VALUES(`error`),
            `applied_at` = CURRENT_TIMESTAMP
    ]]):format(SQL.config.migrationTable)

    return queryAwait("update", query, {
        migrationId,
        resourceName,
        hash,
        status,
        errorText,
    }, { operation = "mark_migration", migration = migrationId })
end

local function columnExists(tableName, columnName)
    local ok, count = queryAwait("scalar", [[
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
            AND table_name = ?
            AND column_name = ?
    ]], { tableName, columnName }, { operation = "column_exists", table = tableName, column = columnName })

    return ok and tonumber(count or 0) > 0
end

local function indexExists(tableName, indexName)
    local ok, count = queryAwait("scalar", [[
        SELECT COUNT(*)
        FROM information_schema.statistics
        WHERE table_schema = DATABASE()
            AND table_name = ?
            AND index_name = ?
    ]], { tableName, indexName }, { operation = "index_exists", table = tableName, index = indexName })

    return ok and tonumber(count or 0) > 0
end

local function quoteIdentifier(value)
    return "`" .. tostring(value):gsub("`", "``") .. "`"
end

local function splitAlterClauses(body)
    local clauses = {}
    local buffer = {}
    local quote = nil
    local depth = 0
    local index = 1

    while index <= #body do
        local char = body:sub(index, index)
        local nextChar = body:sub(index + 1, index + 1)

        if quote then
            buffer[#buffer + 1] = char

            if char == "\\" and quote ~= "`" and nextChar ~= "" then
                index = index + 1
                buffer[#buffer + 1] = body:sub(index, index)
            elseif char == quote then
                if quote ~= "`" and nextChar == quote then
                    index = index + 1
                    buffer[#buffer + 1] = body:sub(index, index)
                else
                    quote = nil
                end
            end
        else
            if char == "'" or char == '"' or char == "`" then
                quote = char
            elseif char == "(" then
                depth = depth + 1
            elseif char == ")" and depth > 0 then
                depth = depth - 1
            end

            if char == "," and depth == 0 and not quote then
                local clause = trim(table.concat(buffer))
                if clause ~= "" then
                    clauses[#clauses + 1] = clause
                end
                buffer = {}
            else
                buffer[#buffer + 1] = char
            end
        end

        index = index + 1
    end

    local tail = trim(table.concat(buffer))
    if tail ~= "" then
        clauses[#clauses + 1] = tail
    end

    return clauses
end

local function matchAddColumnIfNotExists(clause)
    local columnName, definition = clause:match(ADD_COLUMN_IF_NOT_EXISTS_BACKTICK_PATTERN)

    if not columnName then
        columnName, definition = clause:match(ADD_COLUMN_IF_NOT_EXISTS_PLAIN_PATTERN)
    end

    return columnName, definition
end

local function matchAddIndexIfNotExists(clause)
    local indexName, definition = clause:match(ADD_INDEX_IF_NOT_EXISTS_BACKTICK_PATTERN)

    if not indexName then
        indexName, definition = clause:match(ADD_INDEX_IF_NOT_EXISTS_PLAIN_PATTERN)
    end

    if not indexName then
        indexName, definition = clause:match(ADD_KEY_IF_NOT_EXISTS_BACKTICK_PATTERN)
    end

    if not indexName then
        indexName, definition = clause:match(ADD_KEY_IF_NOT_EXISTS_PLAIN_PATTERN)
    end

    return indexName, definition
end

local function isGuardedAlterClause(clause)
    local upper = string.upper(clause)

    return upper:match("^%s*ADD%s+COLUMN%s+IF%s+NOT%s+EXISTS%s+")
        or upper:match("^%s*ADD%s+INDEX%s+IF%s+NOT%s+EXISTS%s+")
        or upper:match("^%s*ADD%s+KEY%s+IF%s+NOT%s+EXISTS%s+")
end

local function parseAlterTable(statement)
    local tableName, body = statement:match(ALTER_TABLE_BACKTICK_PATTERN)

    if not tableName then
        tableName, body = statement:match(ALTER_TABLE_PLAIN_PATTERN)
    end

    return tableName, body
end

local function executeAlterIfNeeded(statement, context)
    local legacyTableName, legacyColumnName, legacyDefinition = statement:match(ALTER_TABLE_ADD_COLUMN_IF_NOT_EXISTS_BACKTICK_PATTERN)

    if not legacyTableName then
        legacyTableName, legacyColumnName, legacyDefinition = statement:match(ALTER_TABLE_ADD_COLUMN_IF_NOT_EXISTS_PLAIN_PATTERN)
    end

    local tableName, body = parseAlterTable(statement)

    if not tableName or not body then
        return nil
    end

    local clauses = splitAlterClauses(body)
    local operations = {}
    local hasGuardedClause = false

    for _, clause in ipairs(clauses) do
        local columnName, columnDefinition = matchAddColumnIfNotExists(clause)
        local indexName, indexDefinition = matchAddIndexIfNotExists(clause)

        if columnName and columnDefinition then
            hasGuardedClause = true
            operations[#operations + 1] = {
                kind = "column",
                name = columnName,
                definition = trim(columnDefinition),
            }
        elseif indexName and indexDefinition then
            hasGuardedClause = true
            operations[#operations + 1] = {
                kind = "index",
                name = indexName,
                definition = trim(indexDefinition),
            }
        elseif isGuardedAlterClause(clause) then
            return false, Core.fail("unsupported_guarded_alter", "Unsupported guarded ALTER TABLE clause.", {
                table = tableName,
                clause = clause,
                file = context and context.file,
                resource = context and context.resource,
            })
        end
    end

    if #operations == 0 then
        return nil
    end

    if hasGuardedClause and #operations ~= #clauses then
        return false, Core.fail("mixed_guarded_alter", "ALTER TABLE mixes guarded and unsupported clauses.", {
            table = tableName,
            file = context and context.file,
            resource = context and context.resource,
        })
    end

    for _, operation in ipairs(operations) do
        if operation.kind == "column" then
            if not columnExists(tableName, operation.name) then
                local query = ("ALTER TABLE %s ADD COLUMN %s %s"):format(
                    quoteIdentifier(tableName),
                    quoteIdentifier(operation.name),
                    operation.definition
                )
                local ok, response = queryAwait("query", query, {}, context)
                if not ok then
                    return false, response
                end
            end
        elseif operation.kind == "index" then
            if not indexExists(tableName, operation.name) then
                local query = ("ALTER TABLE %s ADD INDEX %s %s"):format(
                    quoteIdentifier(tableName),
                    quoteIdentifier(operation.name),
                    operation.definition
                )
                local ok, response = queryAwait("query", query, {}, context)
                if not ok then
                    return false, response
                end
            end
        end
    end

    if legacyTableName and legacyColumnName and legacyDefinition then
        return true, "column_checked"
    end

    return true, "alter_checked"
end

local function executeStatement(statement, context)
    local alterOk, alterResponse = executeAlterIfNeeded(statement, context)
    if alterOk ~= nil then
        return alterOk, alterResponse
    end

    local ok, response = queryAwait("query", statement, {}, context)
    if ok then
        return true, response
    end

    if response and isIgnorableSqlError(response.message) then
        Core.log("warn", "Ignored idempotent SQL warning: " .. response.message, context)
        return true, response
    end

    return false, response
end

local function tableExists(tableName)
    local ok, count = queryAwait("scalar", [[
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
            AND table_name = ?
    ]], { tableName }, { operation = "table_exists", table = tableName })

    return ok and tonumber(count or 0) > 0
end

local function applyLicenseSeeds(resourceName, summary)
    local compat = Core.SQL_COMPAT or {}
    local seeds = compat.licenseSeeds and compat.licenseSeeds[resourceName]

    if type(seeds) ~= "table" or #seeds == 0 then
        return true
    end

    if not tableExists("licenses") then
        summary.warnings[#summary.warnings + 1] = "licenses_table_missing"
        Core.log("warn", "Skipped license seed because `licenses` table does not exist.", {
            resource = resourceName,
            operation = "license_seed",
        })
        return true
    end

    for _, seed in ipairs(seeds) do
        local ok, response = queryAwait("update", "INSERT IGNORE INTO `licenses` (`type`, `label`) VALUES (?, ?)", {
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
        if type(tableName) == "string" and tableName ~= "" and not tableExists(tableName) then
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
    if type(sql) ~= "string" or trim(sql) == "" then
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

    local hash = checksum(sql)
    local migrationId = ("%s:%s:%s"):format(resourceName, entry.id or "sql", hash)
    fileSummary.migration = migrationId
    fileSummary.checksum = hash

    local exists, existingMigration = migrationExists(migrationId)
    if existingMigration and existingMigration.ok == false then
        return false, existingMigration
    end

    if exists and not options.force then
        fileSummary.skipped = true
        fileSummary.reason = "already_applied"
        summary.skipped = summary.skipped + 1
        return true
    end

    local statements = splitStatements(sql)
    local compat = Core.SQL_COMPAT or {}
    local skipPrepared = compat.skipPreparedLicenseBlocks and compat.skipPreparedLicenseBlocks[resourceName]

    for index, rawStatement in ipairs(statements) do
        local statement = trim(rawStatement)
        local statementContext = {
            resource = resourceName,
            migration = migrationId,
            statement = index,
            file = loadPath,
        }

        if skipPrepared and isPreparedLicenseStatement(statement) then
            fileSummary.skipped = fileSummary.skipped + 1
            summary.skipped = summary.skipped + 1
        else
            statement = normalizeStatement(statement)

            local statementOk, response = executeStatement(statement, statementContext)
            if statementOk then
                fileSummary.applied = fileSummary.applied + 1
                summary.applied = summary.applied + 1
            else
                fileSummary.errors = fileSummary.errors + 1
                summary.errors[#summary.errors + 1] = response
                Core.log("error", "SQL statement failed: " .. tostring(response and response.message or response), statementContext)

                if SQL.config.strict or options.strict then
                    markMigration(migrationId, resourceName, hash, "failed", response and response.message or "unknown")
                    return false, response
                end
            end
        end
    end

    markMigration(migrationId, resourceName, hash, fileSummary.errors > 0 and "warning" or "applied", fileSummary.errors > 0 and "completed_with_warnings" or nil)
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
        return result(true, { skipped = true, reason = "auto_sql_disabled" }, nil, nil, context)
    end

    local entries, framework, definition = resolveResourceSql(resourceName, options)
    if #entries == 0 then
        return result(true, {
            skipped = true,
            reason = "no_resource_sql",
            resource = resourceName,
            source = definition and "lyre_bridge" or "legacy",
        }, nil, nil, context)
    end

    if not SQL.ready() then
        return Core.fail("mysql_not_ready", "oxmysql is not ready; cannot prepare SQL.", context)
    end

    local ok, migrationTableError = ensureMigrationTable()
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

    return result(true, summary, nil, nil, context)
end
