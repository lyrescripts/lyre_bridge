function LyreBridge.buildBridge(side)
    local custom = setmetatable({}, {
        __index = function(_, fnName)
            local resourceName = GetCurrentResourceName()
            local fns = LyreBridge.customFunctions[resourceName]
            local fn = fns and fns[fnName]
            if fn then
                return function(_, ...)
                    return fn(...)
                end
            end
            return function() end
        end,
    })

    return setmetatable({ core = {}, custom = custom }, {
        __index = function(self, moduleName)
            local provider = LyreBridge.resolveProvider(side, moduleName)
            if provider then
                rawset(self, moduleName, provider)
            end
            return provider
        end,
    })
end

bridge = LyreBridge.buildBridge(IsDuplicityVersion() and "server" or "client")
