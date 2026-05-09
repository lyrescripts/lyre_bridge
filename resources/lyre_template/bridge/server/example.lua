-- Example bridge server for a custom framework. Duplicate this file under a
-- different name (e.g. `mycore.lua`) and edit the EXAMPLE → MYCORE constant
-- to add a new framework integration without touching lyre_bridge.

local bridge = LyreBridge.bridgeCandidate("EXAMPLE")

function bridge:autoDetect()
    -- Return true when this framework is started on the server.
    return false
end

function bridge:init()
    -- Optional: cache framework references on self for later calls.
    -- self.object = exports["my_framework"]:getSharedObject()
end

-- Add framework-specific overrides below.
-- function bridge:getPlayerFromId(playerId)
--     return self.object.GetPlayerFromId(playerId)
-- end
