local provider = LyreBridge.registerProvider("server", "mysql", "oxmysql", 10)

---Active when the `oxmysql` resource is started.
---@return boolean
function provider:detect()
    return bridge.core.isStarted("oxmysql")
end

---Run a SELECT and return every matching row.
---@param query string SQL string with `?` placeholders.
---@param params? table Positional parameters bound in order.
---@return table[] rows
function provider:query(query, params)
    return MySQL.query.await(query, params)
end

---Run a SELECT and return the first row only.
---@param query string
---@param params? table
---@return table? row `nil` when no row matched.
function provider:single(query, params)
    return MySQL.single.await(query, params)
end

---Run a SELECT and return the first column of the first row.
---@param query string
---@param params? table
---@return any value
function provider:scalar(query, params)
    return MySQL.scalar.await(query, params)
end

---Run an UPDATE / DELETE statement.
---@param query string
---@param params? table
---@return integer affectedRows
function provider:update(query, params)
    return MySQL.update.await(query, params)
end

---Run an INSERT statement.
---@param query string
---@param params? table
---@return integer insertId Inserted id, or the number of affected rows for batch inserts.
function provider:insert(query, params)
    return MySQL.insert.await(query, params)
end

---Prepare and execute a statement, returning the driver's raw result.
---@param query string
---@param params? table
---@return any
function provider:prepare(query, params)
    return MySQL.prepare.await(query, params)
end

---Execute a raw statement without prepared-statement parsing.
---@param query string
---@param params? table
---@return any
function provider:rawExecute(query, params)
    return MySQL.rawExecute.await(query, params)
end

---Run a list of statements atomically.
---@param queries { query: string, values: table }[] Ordered statements to execute.
---@param params? table Optional shared parameters.
---@return boolean committed `true` when the transaction completed without error.
function provider:transaction(queries, params)
    return MySQL.transaction.await(queries, params)
end
