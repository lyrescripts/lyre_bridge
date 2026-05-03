local Core = LyreBridge
local internals = Core._clientInternals or {}
local currentResourceName = internals.currentResourceName or Core.currentResourceName

Core.registerModule("client", "inventory", function()
    local module = {}

    local function frameworkName(bridge)
        return bridge and bridge.__lyre and bridge.__lyre.framework
    end

    local function callProvider(methodName, context)
        context.method = methodName

        for _, provider in ipairs(Core.getProviders("client", "inventory")) do
            if type(provider[methodName]) == "function" and Core.isProviderAvailable(provider, context) then
                local ok, handled, result = pcall(provider[methodName], provider, context)
                if ok and handled then
                    Core.log("debug", "Client inventory provider handled request.", {
                        resource = currentResourceName(),
                        provider = Core.providerName(provider),
                        method = methodName,
                        framework = context.framework,
                    })
                    return true, result
                end

                if not ok then
                    Core.log("warn", "Client inventory provider failed.", {
                        resource = currentResourceName(),
                        provider = Core.providerName(provider),
                        method = methodName,
                        error = tostring(handled),
                    })
                end
            end
        end

        return false
    end

    function module.hasItem(bridge, itemName, amount)
        if type(itemName) ~= "string" or itemName == "" then
            return false
        end

        local handled, result = callProvider("hasItem", {
            bridge = bridge,
            object = bridge and bridge.object,
            framework = frameworkName(bridge),
            itemName = itemName,
            amount = tonumber(amount) or 1,
        })

        return handled and result == true
    end

    return module
end)
