local bridge = LyreBridge.bridgeCandidate("QBOX")

---revivePlayer
---@return boolean
---@public
function bridge:revivePlayer()
	if LyreBridge.isStarted("qbx_medical") then
		TriggerEvent("qbx_medical:client:playerRevived")
		return true
	end

	return false
end

---clearDeathStatus
---@return void
---@public
function bridge:clearDeathStatus()
	if LyreBridge.isStarted("qbx_medical") then
		TriggerServerEvent("qbx_medical:server:setDeathStatus", false)
		TriggerServerEvent("qbx_medical:server:setLaststandStatus", false)
	end
end
