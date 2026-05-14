local provider = LyreBridge.registerProvider("server", "mysql", "oxmysql", 10)

function provider:detect()
    return bridge.core.isStarted("oxmysql")
end

function provider:query(query, params)
    return MySQL.query.await(query, params)
end

function provider:single(query, params)
    return MySQL.single.await(query, params)
end

function provider:scalar(query, params)
    return MySQL.scalar.await(query, params)
end

function provider:update(query, params)
    return MySQL.update.await(query, params)
end

function provider:insert(query, params)
    return MySQL.insert.await(query, params)
end

function provider:prepare(query, params)
    return MySQL.prepare.await(query, params)
end

function provider:rawExecute(query, params)
    return MySQL.rawExecute.await(query, params)
end

function provider:transaction(queries, params)
    return MySQL.transaction.await(queries, params)
end
