local bridge = LyreBridge.bridgeCandidate("STANDALONE")

---revivePlayer
---@param serverId number The server ID of the player to revive
function bridge:revivePlayer(serverId)
	ExecuteCommand("revive " .. serverId)
end
