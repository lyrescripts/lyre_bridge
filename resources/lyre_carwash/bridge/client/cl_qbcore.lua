local bridge = LyreBridge.bridgeCandidate("QBCORE")

---getSelfIdentifier
---@return string
---@public
function bridge:getSelfIdentifier()
	return bridge.object.Functions.GetPlayerData().citizenid
end
