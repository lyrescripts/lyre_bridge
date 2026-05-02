if not LyreBridge or not LyreBridge.setupBridge then
    local runtime = LoadResourceFile("lyre_bridge", "imports/shared.lua")
    assert(runtime, "lyre_bridge imports/shared.lua is missing")

    local fn, err = load(runtime, "@lyre_bridge/imports/shared.lua")
    assert(fn, err)
    fn()
end

local Core = LyreBridge

Core.loadImport("imports/client/helpers.lua")
Core.loadImport("imports/client/setup.lua")
Core.loadImport("imports/client/notifications.lua")
Core.loadImport("imports/client/target.lua")
Core.loadImport("imports/client/vehicle_keys.lua")
Core.loadImport("imports/client/fuel.lua")
Core.loadImport("imports/client/progress.lua")
