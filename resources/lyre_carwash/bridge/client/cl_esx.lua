local bridge = LyreBridge.bridgeCandidate("ESX")

---getSelfIdentifier
---@return string
---@public
function bridge:getSelfIdentifier()
	return bridge.object.GetPlayerData().identifier
end
