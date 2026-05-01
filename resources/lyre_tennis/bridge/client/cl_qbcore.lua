_G.bridge = _G.bridge or {}

local this = "QBCORE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return GetResourceState("qb-core") == "started"
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

---getPlayerName
---@return string
---@public
function bridge:getPlayerName()
	if not self.object then
		return "Unknown"
	end
	local playerData = self.object.Functions.GetPlayerData()
	if not playerData or not playerData.charinfo then
		return "Unknown"
	end
	local firstname = playerData.charinfo.firstname or ""
	local lastname = playerData.charinfo.lastname or ""
	return firstname .. " " .. lastname
end
