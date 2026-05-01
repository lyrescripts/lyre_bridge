_G.bridge = _G.bridge or {}

local this = "EXAMPLE"

_G.bridge[this] = {}
_G.bridge[this].supportsItemMetadata = false

_G.bridge[this].autoDetect = function()
	-- Customize this function
	return false
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@description Initializes the framework bridge
---@return void
---@public
function bridge:init()
	-- Customize this function, this function is executed when the bridge is detected. You can for example set self.object to the shared object of your framework.
end

---getPlayerFromId
---@description Gets a player object with helper methods from their server ID
---@param playerId number The player's server ID
---@return table|boolean Player object with methods or false if not found
---@public
function bridge:getPlayerFromId(playerId)
	-- Edit this function to match your framework's functions

	local player = {}

	player.getIdentifier = function() end

	player.showNotification = function(message) end

	player.getAccount = function(account) end

	player.removeAccountMoney = function(account, amount) end

	player.addAccountMoney = function(account, amount) end

	player.getName = function() end

	player.getJob = function() end

	player.addItem = function(itemName, count, metadata) end

	player.removeItem = function(itemName, count, slot) end

	player.getItemCount = function(itemName) return 0 end

	player.setItemMetadata = function(itemName, slot, metadata) end

	player.getAdminRank = function() end

	return player
end

---getIdFromIdentifier
---@description Gets a player's server ID from their identifier
---@param identifier string The player's identifier
---@return number|boolean Server ID or false if not found
---@public
function bridge:getIdFromIdentifier(identifier)
	-- Edit this function to match your framework's functions
end

---updateOfflinePlayerAccount
---@description Updates an offline player's account balance
---@param identifier string The player's identifier
---@param account string The account type (bank, money, etc.)
---@param amount number The amount to add (positive) or remove (negative)
---@return boolean Success status
---@public
function bridge:updateOfflinePlayerAccount(identifier, account, amount)
	-- Edit this function to match your framework's functions
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

---registerUsableItem
---@description Registers a usable item that triggers the refuel functionality
---@param itemName string The item name to register
---@param callback function The callback function when item is used
---@return void
---@public
function bridge:registerUsableItem(itemName, callback)
	if GetResourceState("ox_inventory") == "started" then
		return
	end

	if GetResourceState("qs-inventory") == "started" then
		return
	end

	-- Edit this function to match your framework's functions
end

---getSocietyMoney
---@description Gets the balance of a society/job account
---@param jobName string The job name
---@return number balance The society account balance
---@public
function bridge:getSocietyMoney(jobName)
	-- Edit this function to match your framework's functions
	return 0
end

---removeSocietyMoney
---@description Removes money from a society/job account
---@param jobName string The job name
---@param amount number The amount to remove
---@return boolean success Whether the operation was successful
---@public
function bridge:removeSocietyMoney(jobName, amount)
	-- Edit this function to match your framework's functions
	return false
end
