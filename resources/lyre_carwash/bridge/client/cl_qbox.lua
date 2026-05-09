local bridge = LyreBridge.bridgeCandidate("QBOX")

---getSelfIdentifier
---@return string
---@public
function bridge:getSelfIdentifier()
	return bridge.object:GetPlayerData().citizenid
end
