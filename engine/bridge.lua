local side = IsDuplicityVersion() and "server" or "client"

bridge = {
    core = {},
    custom = {},
    config = {},
}

local function buildModuleTable(moduleName, methods)
    local module = {}
    for _, methodName in ipairs(methods) do
        module[methodName] = function(...)
            local provider = LyreBridge.resolveProvider(side, moduleName)
            if not provider then
                return
            end
            local fn = provider[methodName]
            if type(fn) ~= "function" then
                return
            end
            return fn(provider, ...)
        end
    end
    return module
end

local sideSpec = LyreBridge.modules[side] or {}
for moduleName, methods in pairs(sideSpec) do
    bridge[moduleName] = buildModuleTable(moduleName, methods)
end

local sharedSpec = LyreBridge.modules.shared or {}
for moduleName, methods in pairs(sharedSpec) do
    if not bridge[moduleName] then
        bridge[moduleName] = buildModuleTable(moduleName, methods)
    end
end

exports("getBridge", function()
    return bridge
end)
