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

loadFile("engine/version_check.lua")

loadFile("bridges/server/mysql/oxmysql.lua")

loadFile("bridges/server/players/esx.lua")
loadFile("bridges/server/players/qbcore.lua")
loadFile("bridges/server/players/qbox.lua")

loadFile("bridges/server/vehicles/default.lua")

loadFile("bridges/server/vehicle_storage/esx.lua")
loadFile("bridges/server/vehicle_storage/qbcore.lua")
loadFile("bridges/server/vehicle_storage/qbox.lua")

loadFile("bridges/server/inventory/ox_inventory.lua")
loadFile("bridges/server/inventory/qs_inventory.lua")
loadFile("bridges/server/inventory/qb.lua")
loadFile("bridges/server/inventory/esx.lua")

loadFile("bridges/server/usable_items/ox_inventory.lua")
loadFile("bridges/server/usable_items/qs_inventory.lua")
loadFile("bridges/server/usable_items/qbox.lua")
loadFile("bridges/server/usable_items/qb.lua")
loadFile("bridges/server/usable_items/esx.lua")

loadFile("bridges/server/society/esx.lua")
loadFile("bridges/server/society/qb.lua")

loadFile("bridges/server/dispatch/zero_r_dispatch.lua")
loadFile("bridges/server/dispatch/fd_dispatch.lua")
loadFile("bridges/server/dispatch/rcore_dispatch.lua")
loadFile("bridges/server/dispatch/ps_dispatch.lua")
loadFile("bridges/server/dispatch/cd_dispatch.lua")
loadFile("bridges/server/dispatch/lb_tablet.lua")

LyreBridge.buildBridge()
