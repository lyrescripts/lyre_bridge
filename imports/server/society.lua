local Core = LyreBridge

Core.registerModule("server", "society", function()
    local module = {}

    local function frameworkName(bridge)
        return bridge and bridge.__lyre and bridge.__lyre.framework
    end

    local function createContext(bridge, jobName, amount)
        return {
            bridge = bridge,
            object = bridge and bridge.object,
            framework = frameworkName(bridge),
            jobName = jobName,
            amount = amount,
        }
    end

    local function callProvider(methodName, context)
        for _, provider in ipairs(Core.getProviders("server", "society")) do
            if type(provider[methodName]) == "function" and Core.isProviderAvailable(provider, context) then
                local ok, handled, result = pcall(provider[methodName], provider, context)
                if ok and handled then
                    Core.log("debug", "Society provider handled request.", {
                        provider = Core.providerName(provider),
                        method = methodName,
                        job = context.jobName,
                        framework = context.framework,
                    })
                    return true, result
                end

                if not ok then
                    Core.log("warn", "Society provider failed.", {
                        provider = Core.providerName(provider),
                        method = methodName,
                        error = tostring(handled),
                    })
                end
            end
        end

        return false
    end

    function module.getMoney(bridge, jobName)
        if not jobName then
            return 0
        end

        local handled, result = callProvider("getMoney", createContext(bridge, jobName))
        return handled and (tonumber(result) or 0) or 0
    end

    function module.removeMoney(bridge, jobName, amount)
        amount = tonumber(amount)
        if not jobName or not amount or amount <= 0 then
            return false
        end

        if module.getMoney(bridge, jobName) < amount then
            return false
        end

        local handled, result = callProvider("removeMoney", createContext(bridge, jobName, amount))
        return handled and result ~= false
    end

    return module
end)
