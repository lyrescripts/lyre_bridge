local bridge = LyreBridge.bridgeCandidate("EXAMPLE")

function bridge:autoDetect()
    -- Return true when your framework/resource should use this bridge.
    return false
end

---init
---@return void
---@public
function bridge:init()
	-- Initialize your framework object here when needed.
end

---revivePlayer
---@return boolean
---@public
function bridge:revivePlayer()
	-- Trigger your framework revive here and return true when it handled the revive.
	return false
end

---clearDeathStatus
---@return void
---@public
function bridge:clearDeathStatus()
	-- Clear your framework dead/laststand state here if it has any.
end
