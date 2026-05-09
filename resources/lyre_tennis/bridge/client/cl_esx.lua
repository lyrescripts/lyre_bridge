local bridge = LyreBridge.bridgeCandidate("ESX")

---getPlayerName
---@return string
---@public
function bridge:getPlayerName()
	if not self.object then
		return "Unknown"
	end
	local playerData = self.object.GetPlayerData()
	if not playerData then
		return "Unknown"
	end
	return playerData.firstName .. " " .. playerData.lastName
end
