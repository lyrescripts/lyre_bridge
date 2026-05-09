local bridge = LyreBridge.bridgeCandidate("EXAMPLE")

function bridge:autoDetect()
    -- Customize this function
    return false
end

---init
---@return void
---@public
function bridge:init()
	-- Customize this function, this function is executed when the bridge is detected. You can for example set self.object to the shared object of your framework.
end

---getPlayerName
---@return string
---@public
function bridge:getPlayerName()
	-- Edit this function to return the player's name according to your framework
	return ""
end
