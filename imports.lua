---Loaded as `shared_script "@lyre_bridge/imports.lua"` from consumer
---resources. Exposes the global `bridge` table fetched from the lyre_bridge
---runtime via the `getBridge` export.
---@type Bridge
bridge = exports.lyre_bridge:getBridge()

if IsDuplicityVersion() then
    local oxmysql = exports.oxmysql
    local consumerResource = GetCurrentResourceName()

    ---Runs one oxmysql method inside the consumer coroutine.
    ---@param method string Oxmysql method name.
    ---@param query string|table SQL query or transaction list.
    ---@param parameters? table Bound query parameters.
    ---@return any result Query result.
    local function awaitMysql(method, query, parameters)
        local request = promise.new()

        oxmysql[method](nil, query, parameters, function(result, errorMessage)
            if errorMessage then
                request:reject(errorMessage)
                return
            end
            request:resolve(result)
        end, consumerResource, true)

        return Citizen.Await(request)
    end

    bridge.mysql = {}
    for _, method in ipairs({
        "insert",
        "prepare",
        "query",
        "rawExecute",
        "scalar",
        "single",
        "transaction",
        "update",
    }) do
        local methodName = method
        bridge.mysql[methodName] = function(query, parameters)
            return awaitMysql(methodName, query, parameters)
        end
    end
end
