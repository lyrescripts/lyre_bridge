local function loadFile(path)
    local source = LoadResourceFile("lyre_bridge", path)
    if not source then
        return
    end
    local fn, err = load(source, "@lyre_bridge/" .. path)
    if not fn then
        print("[lyre_bridge][ERROR] failed to load " .. path .. ": " .. tostring(err))
        return
    end
    fn()
end

loadFile("config.lua")
loadFile("engine/registry.lua")
loadFile("engine/resolver.lua")
loadFile("engine/bridge.lua")

loadFile("engine/configuration.lua")
loadFile("engine/custom.lua")

loadFile("utils/log.lua")
loadFile("utils/isStarted.lua")
loadFile("utils/setDebug.lua")
