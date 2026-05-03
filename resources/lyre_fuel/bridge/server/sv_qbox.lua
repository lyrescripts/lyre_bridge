_G.bridge = _G.bridge or {}

local this = "QBOX"

_G.bridge[this] = {}
_G.bridge[this].supportsItemMetadata = true

_G.bridge[this].autoDetect = function()
	return GetResourceState("qbx_core") == "started"
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@description Initializes the Qbox bridge
---@return void
---@public
function bridge:init()
	self.object = exports["qbx_core"]
end

---getPlayerFromId
---@description Gets a player object with helper methods from their server ID
---@param playerId number The player's server ID
---@return table|boolean Player object with methods or false if not found
---@public
function bridge:getPlayerFromId(playerId)
	local qPlayer = self.object:GetPlayer(playerId)

	if not qPlayer then
		return false
	end

	local player = {
		source = playerId,
		raw = qPlayer,
	}

	player.getIdentifier = function()
		return qPlayer.PlayerData.citizenid
	end

	player.showNotification = function(message)
		self.object:Notify(playerId, message or "", "inform", 5000)
	end

	player.getAccount = function(account)
		if account == "bank" then
			return qPlayer.PlayerData.money.bank
		elseif account == "money" then
			return qPlayer.PlayerData.money.cash
		elseif account == "black_money" then
			return qPlayer.PlayerData.money.crypto or 0
		end
		return 0
	end

	player.removeAccountMoney = function(account, amount)
		local moneyType = "bank"
		if account == "money" then
			moneyType = "cash"
		elseif account == "black_money" then
			moneyType = "crypto"
		end
		qPlayer.Functions.RemoveMoney(moneyType, amount)
	end

	player.addAccountMoney = function(account, amount)
		local moneyType = "bank"
		if account == "money" then
			moneyType = "cash"
		elseif account == "black_money" then
			moneyType = "crypto"
		end
		qPlayer.Functions.AddMoney(moneyType, amount)
	end

	player.getName = function()
		return qPlayer.PlayerData.charinfo.firstname .. " " .. qPlayer.PlayerData.charinfo.lastname
	end

	player.getJob = function()
		return qPlayer.PlayerData.job
	end

	player.getAdminRank = function()
		return bridge.object:GetGroups(playerId) or {}
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
