_G.bridge = _G.bridge or {}

local this = "STANDALONE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return true
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
end

---getPlayerName
---@param playerId number
---@return string
---@public
function bridge:getPlayerName(playerId)
	return GetPlayerName(playerId) or ("Player " .. tostring(playerId))
end

---showNotification
---@param playerId number
---@param message string
---@return void
---@public
function bridge:showNotification(playerId, message)
	TriggerClientEvent(resourceName .. ":client:notify", playerId, message, "primary")
end

---getPlayersByJobs
---@param jobs table
---@return table
---@public
function bridge:getPlayersByJobs(jobs)
	return {}
end

---clearDeathStatus
---@param playerId number
---@return void
---@public
function bridge:clearDeathStatus(playerId)
end
