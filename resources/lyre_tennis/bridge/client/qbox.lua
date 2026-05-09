local bridge = LyreBridge.bridgeCandidate("QBOX")

---getPlayerName
---@return string
---@public
function bridge:getPlayerName()
	if not self.object then
		return "Unknown"
	end
	local playerData = self.object:GetPlayerData()
	if not playerData or not playerData.charinfo then
		return "Unknown"
	end
	local firstname = playerData.charinfo.firstname or ""
	local lastname = playerData.charinfo.lastname or ""
	return firstname .. " " .. lastname
end
