local SQL = LyreBridge.SQL
local Private = SQL._private
local Schema = Private.schema or {}

Private.schema = Schema

function Schema.tableExists(tableName)
    local ok, count = Private.queryAwait("scalar", [[
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
            AND table_name = ?
    ]], { tableName }, { operation = "table_exists", table = tableName })

    return ok and tonumber(count or 0) > 0
end

function Schema.columnExists(tableName, columnName)
    local ok, count = Private.queryAwait("scalar", [[
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
            AND table_name = ?
            AND column_name = ?
    ]], { tableName, columnName }, { operation = "column_exists", table = tableName, column = columnName })

    return ok and tonumber(count or 0) > 0
end

function Schema.indexExists(tableName, indexName)
    local ok, count = Private.queryAwait("scalar", [[
        SELECT COUNT(*)
        FROM information_schema.statistics
        WHERE table_schema = DATABASE()
            AND table_name = ?
            AND index_name = ?
    ]], { tableName, indexName }, { operation = "index_exists", table = tableName, index = indexName })

    return ok and tonumber(count or 0) > 0
end

function Schema.quoteIdentifier(value)
    return "`" .. tostring(value):gsub("`", "``") .. "`"
end
