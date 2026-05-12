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

loadFile("bridges/client/notifications/ox_lib.lua")
loadFile("bridges/client/notifications/esx.lua")
loadFile("bridges/client/notifications/qbcore.lua")
loadFile("bridges/client/notifications/qbox.lua")
loadFile("bridges/client/notifications/gta.lua")

loadFile("bridges/client/players/esx.lua")
loadFile("bridges/client/players/qbcore.lua")
loadFile("bridges/client/players/qbox.lua")

loadFile("bridges/client/target/ox_target.lua")
loadFile("bridges/client/target/qb_target.lua")
loadFile("bridges/client/target/qtarget.lua")

loadFile("bridges/client/inventory/ox_inventory.lua")
loadFile("bridges/client/inventory/qb.lua")
loadFile("bridges/client/inventory/qbox.lua")
loadFile("bridges/client/inventory/esx.lua")

loadFile("bridges/client/vehicles/default.lua")

loadFile("bridges/client/vehicle_keys/qbx_vehiclekeys.lua")
loadFile("bridges/client/vehicle_keys/qb_vehiclekeys.lua")
loadFile("bridges/client/vehicle_keys/qs_vehiclekeys.lua")
loadFile("bridges/client/vehicle_keys/wasabi_carlock.lua")
loadFile("bridges/client/vehicle_keys/mrnewb_vehiclekeys.lua")
loadFile("bridges/client/vehicle_keys/renewed_vehiclekeys.lua")
loadFile("bridges/client/vehicle_keys/mk_vehiclekeys.lua")
loadFile("bridges/client/vehicle_keys/fivecode_carkeys.lua")
loadFile("bridges/client/vehicle_keys/t1ger_keys.lua")
loadFile("bridges/client/vehicle_keys/tgiann_hotwire.lua")
loadFile("bridges/client/vehicle_keys/f_real_car_keys_system.lua")
loadFile("bridges/client/vehicle_keys/ti_vehicle_keys.lua")

loadFile("bridges/client/fuel/lyre_fuel.lua")
loadFile("bridges/client/fuel/ox_fuel.lua")
loadFile("bridges/client/fuel/renewed_fuel.lua")
loadFile("bridges/client/fuel/nd_fuel.lua")
loadFile("bridges/client/fuel/legacy_fuel.lua")
loadFile("bridges/client/fuel/ps_fuel.lua")
loadFile("bridges/client/fuel/lj_fuel.lua")
loadFile("bridges/client/fuel/esx_sna_fuel.lua")
loadFile("bridges/client/fuel/qb_fuel.lua")
loadFile("bridges/client/fuel/qb_sna_fuel.lua")
loadFile("bridges/client/fuel/cdn_fuel.lua")
loadFile("bridges/client/fuel/bigdaddy_fuel.lua")
loadFile("bridges/client/fuel/lc_fuel.lua")
loadFile("bridges/client/fuel/rcore_fuel.lua")
loadFile("bridges/client/fuel/ti_fuel.lua")
loadFile("bridges/client/fuel/frfuel.lua")
loadFile("bridges/client/fuel/native.lua")

loadFile("bridges/client/dispatch/cd_dispatch.lua")
loadFile("bridges/client/dispatch/qs_dispatch.lua")
loadFile("bridges/client/dispatch/ps_dispatch.lua")
loadFile("bridges/client/dispatch/rcore_dispatch.lua")
loadFile("bridges/client/dispatch/core_dispatch.lua")
loadFile("bridges/client/dispatch/tk_dispatch.lua")
loadFile("bridges/client/dispatch/codem_dispatch.lua")

loadFile("bridges/client/progress/ox_lib.lua")
loadFile("bridges/client/progress/native.lua")
