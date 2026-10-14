LyreBridge = LyreBridge or {}
LyreBridge.config = LyreBridge.config or {}

-- [string] → Locale used by every Lyre resource, unless a resource overrides it.
LyreBridge.config.locale = "en"

-- [string] → Interaction system used by every Lyre resource: "marker" or "target".
LyreBridge.config.interact = "marker"

-- [boolean] → Blurs the game behind the menus of every Lyre resource.
LyreBridge.config.backgroundBlur = false

-- [table] → Hides your HUD while a Lyre resource menu is opened, then shows it again.
LyreBridge.config.hud = {
    show = function() end,
    hide = function() end,
}
