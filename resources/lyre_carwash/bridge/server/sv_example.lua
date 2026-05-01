_G.bridge = _G.bridge or {}

local this = "EXAMPLE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	-- Customize this function
	return false
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	-- Customize this function, this function is executed when the bridge is detected. You can for example set self.object to the shared object of your framework.
end

---getPlayerFromId
---@param playerId number
---@return table
---@public
function bridge:getPlayerFromId(playerId)
	local player = {}

	player.getIdentifier = function()
		-- Customize this function
		return "identifier"
	end

	player.showNotification = function(message)
		-- Customize this function
	end

	player.getAccount = function(account)
		-- Customize this function
		return 0
	end

	player.removeAccountMoney = function(account, amount)
		-- Customize this function
	end

	player.addAccountMoney = function(account, amount)
		-- Customize this function
	end

	return player
end

---getIdFromIdentifier
---@param identifier string
---@return number
---@public
function bridge:getIdFromIdentifier(identifier)
	-- Customize this function
	return 0
end

---updateOfflinePlayerAccount
---@param identifier string
---@param account string
---@param amount number
---@return void
---@public
function bridge:updateOfflinePlayerAccount(identifier, account, amount)
	-- Customize this function
end

---expressRefillAction
---@param stationId string
---@param water number
---@param soap number
---@param wax number
---@param maxWater number
---@param maxSoap number
---@param maxWax number
---@param stocks table
---@return void
---@public
function bridge:expressRefillAction(stationId, water, soap, wax, maxWater, maxSoap, maxWax, stocks)
	-- Fill this function if you want to customize the express refill action
	-- If you want to use this, you have to put the config Config.expressRefillAction to "custom"
end

---customRefillFunction
---@param stationId string
---@param water number
---@param soap number
---@param wax number
---@param maxWater number
---@param maxSoap number
---@param maxWax number
---@param stocks table
---@return void
---@public
function bridge:customRefillFunction(stationId, water, soap, wax, maxWater, maxSoap, maxWax, stocks)
	-- Fill this function if you want to customize the refill action
	-- If you want to use this, you have to put the config Config.refillAction to "custom"
end
