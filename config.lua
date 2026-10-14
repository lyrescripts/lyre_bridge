LyreBridge = LyreBridge or {}
LyreBridge.config = LyreBridge.config or {}

-- [string] → Locale used by every Lyre resource, unless a resource overrides it.
LyreBridge.config.locale = "en"

-- [string] → Interaction system used by every Lyre resource: "marker" or "target".
LyreBridge.config.interact = "marker"

-- [boolean] → Blurs the game behind the menus of every Lyre resource.
LyreBridge.config.backgroundBlur = false

-- [table] → Enable info/debug console logs by resource name. Warnings and errors are always printed.
LyreBridge.config.debug = {
    lyre_boatschool = false,
    lyre_bridge = false,
    lyre_carrental = false,
    lyre_carwash = false,
    lyre_context = false,
    lyre_deathscreen = false,
    lyre_drivingschool = false,
    lyre_flightschool = false,
    lyre_fuel = false,
    lyre_garage = false,
    lyre_hunting = false,
    lyre_illegalmissions = false,
    lyre_template = false,
    lyre_tennis = false,
}

-- [table] → Hides your HUD while a Lyre resource menu is opened, then shows it again.
LyreBridge.config.hud = {
    show = function() end,
    hide = function() end,
}
