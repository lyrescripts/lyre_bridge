local Core = LyreBridge
local internals = Core._clientInternals or {}
local currentResourceName = internals.currentResourceName or Core.currentResourceName

Core.registerModule("client", "dispatch", function()
    local module = {}

    local function isAutoProvider(providerName)
        return providerName == nil or providerName == "" or providerName == "auto_detect"
    end

    local function tryProvider(provider, context)
        if type(provider.send) ~= "function" or not Core.isProviderAvailable(provider, context) then
            return false
        end

        local ok, handled, result = pcall(provider.send, provider, context)
        if ok and handled then
            Core.log("debug", "Dispatch provider handled request.", {
                resource = currentResourceName(),
                provider = Core.providerName(provider),
                side = "client",
            })
            return result ~= false
        end

        if not ok then
            Core.log("warn", "Dispatch provider failed.", {
                resource = currentResourceName(),
                provider = Core.providerName(provider),
                side = "client",
                error = tostring(handled),
            })
        end

        return false
    end

    local function tryNamedProvider(providerName, context)
        for _, provider in ipairs(Core.getProviders("client", "dispatch")) do
            if Core.providerMatches(provider, providerName) and tryProvider(provider, context) then
                return true
            end
        end

        return false
    end

    function module.send(payload, options)
        options = options or {}
        if type(payload) ~= "table" then
            return false
        end

        local providerName = options.provider
        if providerName == "none" or providerName == "builtin" then
            return false
        end

        local context = {
            resource = currentResourceName(),
            payload = payload,
            options = options,
        }

        if not isAutoProvider(providerName) then
            return tryNamedProvider(providerName, context)
        end

        if type(options.providers) == "table" then
            for _, configuredProvider in ipairs(options.providers) do
                if tryNamedProvider(configuredProvider, context) then
                    return true
                end
            end

            return false
        end

        for _, provider in ipairs(Core.getProviders("client", "dispatch")) do
            if tryProvider(provider, context) then
                return true
            end
        end

        return false
    end

    return module
end)
