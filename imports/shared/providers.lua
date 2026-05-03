local Core = LyreBridge

Core.providers = Core.providers or {
    shared = {},
    client = {},
    server = {},
}

local function splitList(value)
    local items = {}

    if type(value) ~= "string" or value == "" then
        return items
    end

    for entry in value:gmatch("[^,%s]+") do
        items[#items + 1] = string.lower(entry)
    end

    return items
end

local function readConvar(name)
    if type(GetConvar) ~= "function" then
        return nil
    end

    local sentinel = "__lyre_bridge_unset__"
    local value = GetConvar(name, sentinel)
    if value == sentinel or value == "" then
        return nil
    end

    return value
end

local function providerNames(provider)
    local names = {}

    for _, value in ipairs({
        provider and provider.name,
        provider and provider.resource,
    }) do
        if type(value) == "string" and value ~= "" then
            names[#names + 1] = string.lower(value)
        end
    end

    return names
end

local function providerMatches(provider, providerName)
    providerName = type(providerName) == "string" and string.lower(providerName) or nil
    if not providerName or providerName == "" then
        return false
    end

    for _, name in ipairs(providerNames(provider)) do
        if name == providerName then
            return true
        end
    end

    return false
end

Core.providerMatches = Core.providerMatches or providerMatches

local function containsProvider(provider, list)
    for _, providerName in ipairs(list or {}) do
        if providerMatches(provider, providerName) then
            return true
        end
    end

    return false
end

local function providerConvarNames(side, moduleName, suffix)
    local names = {}

    if side and moduleName then
        names[#names + 1] = ("lyre_bridge:provider:%s:%s:%s"):format(side, moduleName, suffix)
    end

    if moduleName then
        names[#names + 1] = ("lyre_bridge:provider:%s:%s"):format(moduleName, suffix)
    end

    if side then
        names[#names + 1] = ("lyre_bridge:provider:%s:%s"):format(side, suffix)
    end

    names[#names + 1] = "lyre_bridge:provider:" .. suffix
    return names
end

local function forcedProvider(side, moduleName)
    for _, name in ipairs(providerConvarNames(side, moduleName, "force")) do
        local value = readConvar(name)
        if value then
            return string.lower(value)
        end
    end

    return nil
end

local function disabledProviders(side, moduleName)
    local disabled = {}

    for _, name in ipairs(providerConvarNames(side, moduleName, "disabled")) do
        for _, providerName in ipairs(splitList(readConvar(name))) do
            disabled[#disabled + 1] = providerName
        end
    end

    return disabled
end

local function sortProviders(left, right)
    local leftPriority = tonumber(left.priority) or 1000
    local rightPriority = tonumber(right.priority) or 1000

    if leftPriority == rightPriority then
        return tostring(left.name or "") < tostring(right.name or "")
    end

    return leftPriority < rightPriority
end

function Core.registerProvider(side, moduleName, provider)
    if type(side) ~= "string" or type(moduleName) ~= "string" or type(provider) ~= "table" then
        return false, Core.fail("invalid_provider_registration", "Provider registration expects side, module name and provider table.")
    end

    provider.name = provider.name or provider.resource or moduleName
    provider.__lyreSide = side
    provider.__lyreModule = moduleName

    Core.providers[side] = Core.providers[side] or {}
    Core.providers[side][moduleName] = Core.providers[side][moduleName] or {}
    Core.providers[side][moduleName][#Core.providers[side][moduleName] + 1] = provider
    table.sort(Core.providers[side][moduleName], sortProviders)

    return true, provider
end

function Core.getProviders(side, moduleName)
    local providers = {}
    local shared = Core.providers.shared and Core.providers.shared[moduleName]
    local scoped = Core.providers[side] and Core.providers[side][moduleName]

    for _, provider in ipairs(shared or {}) do
        providers[#providers + 1] = provider
    end

    for _, provider in ipairs(scoped or {}) do
        providers[#providers + 1] = provider
    end

    table.sort(providers, sortProviders)
    return providers
end

function Core.isProviderAvailable(provider, context)
    if type(provider) ~= "table" then
        return false
    end

    if provider.enabled == false then
        return false
    end

    local side = provider.__lyreSide
    local moduleName = provider.__lyreModule
    local forced = forcedProvider(side, moduleName)
    if forced and not providerMatches(provider, forced) then
        return false
    end

    if containsProvider(provider, disabledProviders(side, moduleName)) then
        return false
    end

    if type(provider.isAvailable) == "function" then
        local ok, result = pcall(provider.isAvailable, provider, context)
        return ok and result ~= false and result ~= nil
    end

    if type(provider.resource) == "string" and provider.resource ~= "" then
        return Core.isStarted(provider.resource)
    end

    return true
end

function Core.providerName(provider)
    if type(provider) ~= "table" then
        return "unknown"
    end

    return provider.name or provider.resource or provider.__lyreModule or "unknown"
end
