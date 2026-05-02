local Core = LyreBridge
local function readBoolConvar(name, default)
    if type(GetConvar) ~= "function" then
        return default
    end

    local value = string.lower(tostring(GetConvar(name, default and "true" or "false")))
    return value == "true" or value == "1" or value == "yes" or value == "on"
end

local function readNumberConvar(name, default)
    if type(GetConvar) ~= "function" then
        return default
    end

    local value = tonumber(GetConvar(name, tostring(default)))
    return value or default
end

local function readStringConvar(name, default)
    if type(GetConvar) ~= "function" then
        return default
    end

    local sentinel = "__lyre_bridge_unset__"
    local value = GetConvar(name, sentinel)
    if value == sentinel or value == "" then
        return default
    end

    return value
end

local function readOptionalConvar(name)
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

local configTypes = {
    debug = "boolean",
    failHard = "boolean",
    wrapBridgeCalls = "boolean",
    resourceStateCacheMs = "number",
    locale = "string",
    defaultLocale = "string",
    fallbackLocale = "string",
    bridge = "string",
    checkForUpdates = "boolean",
    backgroundBlur = "boolean",
    interactSystem = "string",
}

local configConvarKeys = {
    wrapBridgeCalls = { "wrapCalls", "wrapBridgeCalls" },
    resourceStateCacheMs = { "stateCacheMs", "resourceStateCacheMs" },
    interactSystem = { "interact", "interactSystem" },
}

local commonConfigKeys = {
    locale = true,
    defaultLocale = true,
    fallbackLocale = true,
    bridge = true,
    checkForUpdates = true,
    backgroundBlur = true,
    interactSystem = true,
}

local function parseConfigValue(value, valueType, default)
    if value == nil then
        return nil
    end

    if valueType == "boolean" then
        if type(value) == "boolean" then
            return value
        end

        local lower = string.lower(tostring(value))
        return lower == "true" or lower == "1" or lower == "yes" or lower == "on"
    end

    if valueType == "number" then
        return tonumber(value) or default
    end

    return value
end

local function addConvarName(names, seen, name)
    if type(name) ~= "string" or name == "" or seen[name] then
        return
    end

    seen[name] = true
    names[#names + 1] = name
end

local function getConvarKeys(key)
    local keys = configConvarKeys[key]
    if type(keys) == "table" then
        return keys
    end

    return { key }
end

local function currentResourceName()
    if type(GetCurrentResourceName) == "function" then
        return GetCurrentResourceName()
    end

    return "unknown"
end

Core.config.debug = readBoolConvar("lyre_bridge:debug", Core.config.debug)
Core.config.failHard = readBoolConvar("lyre_bridge:failHard", Core.config.failHard)
Core.config.wrapBridgeCalls = readBoolConvar("lyre_bridge:wrapCalls", Core.config.wrapBridgeCalls)
Core.config.resourceStateCacheMs = readNumberConvar("lyre_bridge:stateCacheMs", Core.config.resourceStateCacheMs)
Core.config.locale = readStringConvar("lyre_bridge:locale", Core.config.locale)
Core.config.defaultLocale = readStringConvar("lyre_bridge:defaultLocale", Core.config.defaultLocale)
Core.config.fallbackLocale = readStringConvar("lyre_bridge:fallbackLocale", Core.config.fallbackLocale)
Core.config.bridge = readStringConvar("lyre_bridge:bridge", Core.config.bridge)
Core.config.checkForUpdates = readBoolConvar("lyre_bridge:checkForUpdates", Core.config.checkForUpdates)
Core.config.backgroundBlur = readBoolConvar("lyre_bridge:backgroundBlur", Core.config.backgroundBlur)
Core.config.interactSystem = readStringConvar("lyre_bridge:interact", readStringConvar("lyre_bridge:interactSystem", Core.config.interactSystem))

function Core.getConfig(key, default)
    if default == nil then
        default = Core.config[key]
    end

    local valueType = configTypes[key] or type(default)
    local names = {}
    local seen = {}

    for _, convarKey in ipairs(getConvarKeys(key)) do
        addConvarName(names, seen, "lyre_bridge:" .. convarKey)
    end

    for _, name in ipairs(names) do
        local value = readOptionalConvar(name)
        if value ~= nil then
            return parseConfigValue(value, valueType, default)
        end
    end

    return default
end

function Core.getResourceConfig(resourceName, key, default)
    if type(resourceName) ~= "string" or resourceName == "" then
        resourceName = currentResourceName()
    end

    local resourceDefaults = Core._resourceConfigDefaults[resourceName]
    if default == nil and type(resourceDefaults) == "table" then
        default = resourceDefaults[key]
    end

    local globalDefaults = Core.config.resourceDefaults
    if default == nil and type(globalDefaults) == "table" and type(globalDefaults[resourceName]) == "table" then
        default = globalDefaults[resourceName][key]
    end

    if default == nil then
        default = Core.config[key]
    end

    local valueType = configTypes[key] or type(default)
    local names = {}
    local seen = {}

    for _, convarKey in ipairs(getConvarKeys(key)) do
        addConvarName(names, seen, "lyre_bridge:" .. resourceName .. ":" .. convarKey)
    end

    local resourceConvars = Core.config.resourceConvars
    if type(resourceConvars) == "table" and type(resourceConvars[resourceName]) == "table" then
        local aliases = resourceConvars[resourceName][key]
        if type(aliases) == "table" then
            for _, name in ipairs(aliases) do
                addConvarName(names, seen, name)
            end
        elseif type(aliases) == "string" then
            addConvarName(names, seen, aliases)
        end
    end

    for _, convarKey in ipairs(getConvarKeys(key)) do
        addConvarName(names, seen, resourceName .. ":" .. convarKey)
    end

    for _, convarKey in ipairs(getConvarKeys(key)) do
        addConvarName(names, seen, "lyre_bridge:" .. convarKey)
    end

    for _, name in ipairs(names) do
        local value = readOptionalConvar(name)
        if value ~= nil then
            return parseConfigValue(value, valueType, default)
        end
    end

    return default
end

function Core.getLocale(resourceName, default)
    return Core.getResourceConfig(resourceName, "locale", default or Core.config.locale)
end

function Core.createResourceConfig(resourceName, config, defaults)
    if type(resourceName) ~= "string" or resourceName == "" then
        resourceName = currentResourceName()
    end

    if type(config) ~= "table" then
        config = {}
    end

    if type(defaults) == "table" then
        Core._resourceConfigDefaults[resourceName] = Core._resourceConfigDefaults[resourceName] or {}
        for key, value in pairs(defaults) do
            Core._resourceConfigDefaults[resourceName][key] = value
        end
    end

    local previousMeta = getmetatable(config)
    local previousIndex = previousMeta and previousMeta.__index
    local nextMeta = {}

    if type(previousMeta) == "table" then
        for key, value in pairs(previousMeta) do
            nextMeta[key] = value
        end
    end

    nextMeta.__index = function(tbl, key)
        if commonConfigKeys[key] then
            return Core.getResourceConfig(resourceName, key)
        end

        if type(previousIndex) == "function" then
            return previousIndex(tbl, key)
        end

        if type(previousIndex) == "table" then
            return previousIndex[key]
        end

        return nil
    end

    return setmetatable(config, nextMeta)
end
