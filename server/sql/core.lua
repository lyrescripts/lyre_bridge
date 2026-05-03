LyreBridge = LyreBridge or {}

local Core = LyreBridge
local SQL = Core.SQL or {}
local Private = SQL._private or {}

Core.SQL = SQL
SQL._private = Private

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

function Private.result(ok, data, code, message, context)
    if ok then
        return {
            ok = true,
            data = data,
            context = context,
        }
    end

    return Core.fail(code, message, context)
end

function Private.trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function Private.queryAwait(method, query, params, context)
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
    local ok, response = Private.queryAwait("query", query, params, { operation = "query" })
    if not ok then
        return response
    end

    return Private.result(true, response)
end

function SQL.single(query, params)
    local ok, response = Private.queryAwait("single", query, params, { operation = "single" })
    if not ok then
        return response
    end

    return Private.result(true, response)
end

function SQL.scalar(query, params)
    local ok, response = Private.queryAwait("scalar", query, params, { operation = "scalar" })
    if not ok then
        return response
    end

    return Private.result(true, response)
end

function SQL.update(query, params)
    local ok, response = Private.queryAwait("update", query, params, { operation = "update" })
    if not ok then
        return response
    end

    return Private.result(true, response)
end

function SQL.insert(query, params)
    local ok, response = Private.queryAwait("insert", query, params, { operation = "insert" })
    if not ok then
        return response
    end

    return Private.result(true, response)
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

    return Private.result(true, response)
end
