local bridge = LyreBridge.bridgeCandidate("QBCORE")

---revivePlayer
---@return boolean
---@public
function bridge:revivePlayer()
	local handled = false

	if LyreBridge.isStarted("qb-ambulancejob") then
		local success = pcall(function()
			exports["qb-ambulancejob"]:RevivePlayer(Config.respawn.health)
		end)

		if success then
			handled = true
		end
	end

	if LyreBridge.isStarted("hospital") or LyreBridge.isStarted("qb-ambulancejob") then
		TriggerEvent("hospital:client:Revive")
		TriggerServerEvent("hospital:server:SetDeathStatus", false)
		TriggerServerEvent("hospital:server:SetLaststandStatus", false)
		return true
	end

	return handled
end

---clearDeathStatus
---@return void
---@public
function bridge:clearDeathStatus()
	TriggerServerEvent("hospital:server:SetDeathStatus", false)
	TriggerServerEvent("hospital:server:SetLaststandStatus", false)
end
