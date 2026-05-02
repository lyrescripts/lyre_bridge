if not LyreBridge or not LyreBridge.setupBridge then
    local runtime = LoadResourceFile("lyre_bridge", "imports/shared.lua")
    assert(runtime, "lyre_bridge imports/shared.lua is missing")

    local fn, err = load(runtime, "@lyre_bridge/imports/shared.lua")
    assert(fn, err)
    fn()
end

local Core = LyreBridge

Core.loadImport("imports/server/helpers.lua")
Core.loadImport("imports/server/setup.lua")
Core.loadImport("imports/server/sql.lua")
Core.loadImport("imports/server/framework.lua")
Core.loadImport("imports/server/players.lua")
