local Core = LyreBridge

Core.registerModule("server", "usableItems", function()
    local module = {}

    local function callProvider(context)
        for _, provider in ipairs(Core.getProviders("server", "usableItems")) do
            if type(provider.register) == "function" and Core.isProviderAvailable(provider, context) then
                local ok, handled, result = pcall(provider.register, provider, context)
                if ok and handled then
                    Core.log("debug", "Usable item provider handled request.", {
                        provider = Core.providerName(provider),
                        item = context.itemName,
                        framework = context.framework,
                    })
                    return result ~= false
                end

                if not ok then
                    Core.log("warn", "Usable item provider failed.", {
                        provider = Core.providerName(provider),
                        error = tostring(handled),
                    })
                end
            end
        end

        return false
    end

    function module.register(bridge, itemName, callback)
        if type(itemName) ~= "string" or itemName == "" or type(callback) ~= "function" then
            return false
        end

        return callProvider({
            bridge = bridge,
            object = bridge and bridge.object,
            framework = bridge and bridge.__lyre and bridge.__lyre.framework,
            itemName = itemName,
            callback = callback,
        })
    end

    return module
end)
