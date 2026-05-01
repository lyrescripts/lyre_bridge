_G.bridge = _G.bridge or {}

local this = "ESX"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return GetResourceState("es_extended") == "started"
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

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
	if GetResourceState("esx_ambulancejob") == "started" then
		TriggerEvent("esx_ambulancejob:revive")
		return true
	end

	return false
end
