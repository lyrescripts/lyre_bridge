_G.bridge = _G.bridge or {}

local this = "ESX"

_G.bridge[this] = {}
_G.bridge[this].supportsItemMetadata = false

_G.bridge[this].autoDetect = function()
	return GetResourceState("es_extended") == "started"
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@description Initializes the ESX bridge
---@return void
---@public
function bridge:init()
	self.object = exports["es_extended"]:getSharedObject()
end

---getPlayerFromId
---@description Gets a player object with helper methods from their server ID
---@param playerId number The player's server ID
---@return table|boolean Player object with methods or false if not found
---@public
function bridge:getPlayerFromId(playerId)
	local xPlayer = self.object.GetPlayerFromId(playerId)

	if not xPlayer then
		return false
	end

	local player = {
		source = playerId,
		raw = xPlayer,
	}

	player.getIdentifier = function()
		return xPlayer.identifier
	end

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

	player.getName = function()
		return xPlayer.getName()
	end

	player.getJob = function()
		return xPlayer.getJob()
	end

	player.getAdminRank = function()
		-- For ESX, admin ranks are usually stored in the users table or through permissions
		-- This is a basic implementation - you may need to adjust based on your admin system
		return {
			[xPlayer.getGroup and xPlayer.getGroup() or nil] = true,
		}
	end

	return player
end


---expressRefillAction
---@description Custom express refill action (override in bridge if Config.refillMission.expressRefillAction = "custom")
---@param stationId string The station ID
---@param fuelType string The fuel type being refilled
---@param amount number The amount to refill
---@return void
---@public
function bridge:expressRefillAction(stationId, fuelType, amount)
	-- Fill this function if you want to customize the express refill action
	-- If you want to use this, set Config.refillMission.expressRefillAction to "custom"
end

---customRefillFunction
---@description Custom refill mission function (override in bridge if Config.refillMission.missionRefillAction = "custom")
---@param stationId string The station ID
---@param fuelType string The fuel type being refilled
---@param amount number The amount to refill
---@return void
---@public
function bridge:customRefillFunction(stationId, fuelType, amount)
	-- Fill this function if you want to customize the refill mission action
	-- If you want to use this, set Config.refillMission.missionRefillAction to "custom"
end

---nonLiquidRefillAction
---@description Custom refill action for non-liquid fuel types like electricity (override in bridge if Config.refillMission.nonLiquidRefillAction = "custom")
---@param stationId string The station ID
---@param fuelType string The fuel type being refilled (e.g., "electric")
---@param amount number The amount to refill
---@return void
---@public
function bridge:nonLiquidRefillAction(stationId, fuelType, amount)
	-- Fill this function if you want to customize the non-liquid refill action
	-- If you want to use this, set Config.refillMission.nonLiquidRefillAction to "custom"
	-- This is used for fuel types like electricity where mission refill doesn't make sense
end
