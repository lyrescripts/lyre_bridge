local function readConvar(name)
    local sentinel = "__unset__"
    local value = GetConvar(name, sentinel)
    if value == sentinel or value == "" then
        return nil
    end
    return value
end

for key in pairs(LyreBridge.config) do
    local override = readConvar("lyre_bridge:" .. key)
    if override then
        LyreBridge.config[key] = override
    end
end

function LyreBridge.resolveConfigValue(resourceName, key, fallback)
    local override = readConvar("lyre_bridge:" .. resourceName .. ":" .. key)
    if override ~= nil then
        return override
    end
    if fallback ~= nil then
        return fallback
    end
    return LyreBridge.config[key]
end

function LyreBridge.registerResourceConfiguration(resourceName, config)
    config = config or {}
    local resolved = {}

    for key, value in pairs(LyreBridge.config) do
        resolved[key] = value
    end
    for key, value in pairs(config) do
        resolved[key] = value
    end
    for key in pairs(resolved) do
        local override = readConvar("lyre_bridge:" .. resourceName .. ":" .. key)
        if override ~= nil then
            resolved[key] = override
        end
    end

    return resolved
end

function bridge.config.register(config)
    local resourceName = GetInvokingResource() or GetCurrentResourceName()
    return LyreBridge.registerResourceConfiguration(resourceName, config)
end

function bridge.config.get(key, fallback)
    local resourceName = GetInvokingResource() or GetCurrentResourceName()
    return LyreBridge.resolveConfigValue(resourceName, key, fallback)
end
