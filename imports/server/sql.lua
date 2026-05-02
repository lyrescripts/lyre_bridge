local Core = LyreBridge
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
