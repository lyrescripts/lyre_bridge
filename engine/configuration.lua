---@param name string
---@return string?
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

---Resolve a single configuration key for the given resource, honoring its
---per-resource convar override before falling back to the global default.
---@param resourceName string
---@param key string
---@param fallback? any
---@return any
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

---Build a flat configuration table for a resource by layering the global
---defaults, the resource-provided overrides, then any matching convars on top.
---@param resourceName string
---@param config? table<string, any>
---@return table<string, any>
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

---Register a resource configuration. The invoking resource is detected
---through `GetInvokingResource`. Returns the resolved, flat config table.
---@param config? table<string, any>
---@return table<string, any>
function bridge.config.register(config)
    local resourceName = GetInvokingResource() or GetCurrentResourceName()
    return LyreBridge.registerResourceConfiguration(resourceName, config)
end

---Read a single configuration value for the invoking resource.
---@param key string
---@param fallback? any
---@return any
function bridge.config.get(key, fallback)
    local resourceName = GetInvokingResource() or GetCurrentResourceName()
    return LyreBridge.resolveConfigValue(resourceName, key, fallback)
end
