local bridge = LyreBridge.bridgeCandidate("QBCORE")

---revivePlayer
---@param serverId number The server ID of the player to revive
---@return void
---@public
function bridge:revivePlayer(serverId)
	ExecuteCommand("revive " .. serverId)
end
