_G.bridge = _G.bridge or {}

local this = "QBOX"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("qbx_core")
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	self.object = exports["qbx_core"]
end

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
