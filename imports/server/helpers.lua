local Core = LyreBridge
local function currentResourceName()
    if type(GetCurrentResourceName) == "function" then
        return GetCurrentResourceName()
    end

    return "unknown"
end

local function readBoolConvar(name, default)
    if type(GetConvar) ~= "function" then
        return default
    end

    local sentinel = "__lyre_bridge_unset__"
    local value = GetConvar(name, sentinel)
    if value == sentinel or value == "" then
        return default
    end

    value = string.lower(tostring(value))
    return value == "true" or value == "1" or value == "yes" or value == "on"
end

local function resourceSqlStrict(resourceName, default)
    local names = {
        "lyre_bridge:" .. resourceName .. ":sqlStrict",
        resourceName .. ":sqlStrict",
    }

    local value = default
    for _, name in ipairs(names) do
        value = readBoolConvar(name, value)
    end

    return value
end

local function getRequiredFunctions(config, options)
    if type(options.required) == "table" then
        return options.required
    end

    if type(config) == "table" then
        return config.bridgeRequiredServerFunctions
    end

    return nil
end

Core._serverInternals = {
    currentResourceName = currentResourceName,
    readBoolConvar = readBoolConvar,
    resourceSqlStrict = resourceSqlStrict,
    getRequiredFunctions = getRequiredFunctions,
}
