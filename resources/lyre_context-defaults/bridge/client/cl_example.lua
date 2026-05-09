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

---revivePlayer
---@param serverId number The server ID of the player to revive
---@return void
---@public
function bridge:revivePlayer(serverId)
	-- Edit this command to match your framework's revive command
	ExecuteCommand("revive " .. serverId)
end
