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

function LyreBridge.registerResourceConfiguration(resourceName, config)
    config = config or {}
    return setmetatable(config, {
        __index = function(_, key)
            local override = readConvar("lyre_bridge:" .. resourceName .. ":" .. key)
            if override ~= nil then
                return override
            end
            return LyreBridge.config[key]
        end,
    })
end
