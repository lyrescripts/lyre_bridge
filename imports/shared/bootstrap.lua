LyreBridge = LyreBridge or {}

local Core = LyreBridge

Core.version = Core.version or "1.0.2"
Core.config = Core.config or {}

function Core.currentResourceName()
    if type(GetCurrentResourceName) == "function" then
        return GetCurrentResourceName()
    end

    return "unknown"
end

if not Core._bridgeConfigLoaded and type(LoadResourceFile) == "function" then
    local configRuntime = LoadResourceFile("lyre_bridge", "config.lua")

    if configRuntime then
        local configFn, configErr = load(configRuntime, "@lyre_bridge/config.lua")
        if configFn then
            local ok, err = pcall(configFn)
            if not ok then
                print("[lyre_bridge][WARN] Failed to run config.lua: " .. tostring(err))
            end
        else
            print("[lyre_bridge][WARN] Failed to load config.lua: " .. tostring(configErr))
        end
    end

    Core = LyreBridge
    Core.config = Core.config or {}
    Core._bridgeConfigLoaded = true
end

Core.modules = Core.modules or { shared = {}, client = {}, server = {} }
Core._stateCache = Core._stateCache or {}
Core.resources = Core.resources or {}
Core._resourceConfigDefaults = Core._resourceConfigDefaults or {}
Core._internals = Core._internals or {}

local defaultConfig = {
    debug = false,
    failHard = false,
    wrapBridgeCalls = true,
    resourceStateCacheMs = 2500,
    locale = "en",
    defaultLocale = "en",
    fallbackLocale = "en",
    bridge = "auto_detect",
    checkForUpdates = true,
    backgroundBlur = false,
    interactSystem = "marker",
    defaultDetectionOrder = { "ESX", "QBCORE", "STANDALONE", "EXAMPLE" },
}

for key, value in pairs(defaultConfig) do
    if Core.config[key] == nil then
        Core.config[key] = value
    end
end
