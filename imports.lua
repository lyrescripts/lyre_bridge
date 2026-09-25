---Loaded as `shared_script "@lyre_bridge/imports.lua"` from consumer
---resources. Exposes the global `bridge` table fetched from the lyre_bridge
---runtime via the `getBridge` export.
---@type Bridge
bridge = exports.lyre_bridge:getBridge()
