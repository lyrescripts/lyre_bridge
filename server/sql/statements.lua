local Core = LyreBridge
local SQL = Core.SQL
local Private = SQL._private
local Schema = Private.schema
local Statements = Private.statements or {}

Private.statements = Statements

local function trim(value)
    return Private.trim(value)
end

local function queryAwait(method, query, params, context)
    return Private.queryAwait(method, query, params, context)
end

local function checksum(text)
    local hash = 7

    for index = 1, #text do
        hash = (hash * 31 + string.byte(text, index)) % 4294967291
    end

    return ("%08x"):format(hash)
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
            if not Schema.columnExists(tableName, operation.name) then
                local query = ("ALTER TABLE %s ADD COLUMN %s %s"):format(
                    Schema.quoteIdentifier(tableName),
                    Schema.quoteIdentifier(operation.name),
                    operation.definition
                )
                local ok, response = queryAwait("query", query, {}, context)
                if not ok then
                    return false, response
                end
            end
        elseif operation.kind == "index" then
            if not Schema.indexExists(tableName, operation.name) then
                local query = ("ALTER TABLE %s ADD INDEX %s %s"):format(
                    Schema.quoteIdentifier(tableName),
                    Schema.quoteIdentifier(operation.name),
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

Statements.checksum = checksum
Statements.execute = executeStatement
Statements.isPreparedLicenseStatement = isPreparedLicenseStatement
Statements.normalize = normalizeStatement
Statements.split = splitStatements
