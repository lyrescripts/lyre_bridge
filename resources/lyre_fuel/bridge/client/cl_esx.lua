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

---getPlayerJob
---@description Gets the player's current job
---@return table|nil job The job data {name, label, grade, grade_name, grade_label} or nil if unemployed/no job
---@public
function bridge:getPlayerJob()
	local playerData = self.object.GetPlayerData()
	if not playerData or not playerData.job then
		return nil
	end

	local job = playerData.job

	-- Return nil if player is unemployed (no society account)
	if job.name == "unemployed" then
		return nil
	end

	return {
		name = job.name,
		label = job.label,
		grade = job.grade,
		grade_name = job.grade_name,
		grade_label = job.grade_label,
	}
end
