local bridge = LyreBridge.bridgeCandidate("ESX")

---init
---@return void
---@public
function bridge:init()
	self.object = exports["es_extended"]:getSharedObject()

	AddEventHandler("esx:onPlayerDeath", function()
		if not isPlayerDead and startDeathscreen then
			startDeathscreen()
		end
	end)

	AddEventHandler("esx:onPlayerSpawn", function()
		if isPlayerDead and finishDeathscreen then
			finishDeathscreen(false)
		end
	end)
end

---revivePlayer
---@return boolean
---@public
function bridge:revivePlayer()
	if LyreBridge.isStarted("esx_ambulancejob") then
		TriggerEvent("esx_ambulancejob:revive")
		TriggerServerEvent("esx_ambulancejob:setDeathStatus", false)
		return true
	end

	return false
end

---clearDeathStatus
---@return void
---@public
function bridge:clearDeathStatus()
	if LyreBridge.isStarted("esx_ambulancejob") then
		TriggerServerEvent("esx_ambulancejob:setDeathStatus", false)
	end
end
