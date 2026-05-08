_G.bridge = _G.bridge or {}

local this = "QBCORE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("qb-core")
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	self.object = exports["qb-core"]:GetCoreObject()
end

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
