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
end

---getPlayerName
---@return string
---@public
function bridge:getPlayerName()
	if not self.object then
		return "Unknown"
	end
	local playerData = self.object.GetPlayerData()
	if not playerData then
		return "Unknown"
	end
	return playerData.firstName .. " " .. playerData.lastName
end
