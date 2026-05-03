-- Example: wrap SQL calls with project logging.
--[[
LyreBridge.registerModule("server", "projectSql", function()
    local sql = LyreBridge.getModule("server", "sql")

    return {
        query = function(query, params)
            print("[projectSql] " .. query)
            return sql.query(query, params)
        end,
    }
end)
]]
