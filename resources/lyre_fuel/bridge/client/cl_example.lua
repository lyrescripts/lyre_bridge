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

---getPlayerJob
---@description Gets the current player's job data
---@return table|nil job The player job object, or nil if not available
---@public
function bridge:getPlayerJob()
	-- Edit this function to match your framework's functions
end
