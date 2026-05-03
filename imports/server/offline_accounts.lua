local Core = LyreBridge

Core.registerModule("server", "offlineAccounts", function()
    local module = {}

    local function frameworkName(bridge)
        return bridge and bridge.__lyre and bridge.__lyre.framework
    end

    local function callProvider(context)
        for _, provider in ipairs(Core.getProviders("server", "offlineAccounts")) do
            if type(provider.update) == "function" and Core.isProviderAvailable(provider, context) then
                local ok, handled, result = pcall(provider.update, provider, context)
                if ok and handled then
                    Core.log("debug", "Offline account provider handled request.", {
                        provider = Core.providerName(provider),
                        account = context.account,
                        framework = context.framework,
                    })
                    return result ~= false
                end

                if not ok then
                    Core.log("warn", "Offline account provider failed.", {
                        provider = Core.providerName(provider),
                        error = tostring(handled),
                    })
                end
            end
        end

        return false
    end

    function module.update(bridge, identifier, account, amount)
        amount = tonumber(amount)
        if not identifier or not account or not amount then
            return false
        end

        return callProvider({
            bridge = bridge,
            object = bridge and bridge.object,
            framework = frameworkName(bridge),
            identifier = identifier,
            account = account,
            amount = amount,
        })
    end

    return module
end)
