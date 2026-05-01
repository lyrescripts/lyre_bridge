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

---getPlayerFromId
---@param playerId number
---@return table
---@public
function bridge:getPlayerFromId(playerId)
	local xPlayer = self.object.GetPlayerFromId(playerId)

	if not xPlayer then
		return false
	end

	local player = {}

	player.showNotification = function(message)
		xPlayer.showNotification(message)
	end

	player.getAccount = function(account)
		return xPlayer.getAccount(account).money
	end

	player.removeAccountMoney = function(account, amount)
		xPlayer.removeAccountMoney(account, amount)
	end

	player.addAccountMoney = function(account, amount)
		xPlayer.addAccountMoney(account, amount)
	end

	return player
end
