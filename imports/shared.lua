LyreBridge = LyreBridge or {}

local Core = LyreBridge

local function loadImport(path)
    Core._loadedImportFiles = Core._loadedImportFiles or {}
    if Core._loadedImportFiles[path] then
        return true
    end

    local runtime = LoadResourceFile("lyre_bridge", path)
    assert(runtime, "lyre_bridge " .. path .. " is missing")

    local fn, err = load(runtime, "@lyre_bridge/" .. path)
    assert(fn, err)
    fn()

    Core._loadedImportFiles[path] = true
    return true
end

Core.loadImport = Core.loadImport or loadImport

Core.loadImport("imports/shared/bootstrap.lua")
Core.loadImport("imports/shared/config.lua")
Core.loadImport("imports/shared/runtime.lua")
Core.loadImport("imports/shared/defaults.lua")
Core.loadImport("imports/shared/setup.lua")
