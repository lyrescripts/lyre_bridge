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

	local player = {}

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

	player.addItem = function(itemName, count, metadata)
		if GetResourceState("ox_inventory") == "started" then
			exports.ox_inventory:AddItem(playerId, itemName, count, metadata)
			return
		end

		xPlayer.addInventoryItem(itemName, count, metadata)
	end

	player.removeItem = function(itemName, count, slot)
		if GetResourceState("ox_inventory") == "started" then
			exports.ox_inventory:RemoveItem(playerId, itemName, count, nil, slot)
			return
		end

		xPlayer.removeInventoryItem(itemName, count)
	end

	player.getItemCount = function(itemName)
		if GetResourceState("ox_inventory") == "started" then
			local success, count = pcall(function()
				return exports.ox_inventory:Search(playerId, "count", itemName)
			end)

			return success and (count or 0) or 0
		end

		local item = xPlayer.getInventoryItem(itemName)
		return item and item.count or 0
	end

	player.setItemMetadata = function(itemName, slot, metadata)
		if GetResourceState("ox_inventory") == "started" and slot then
			exports.ox_inventory:SetMetadata(playerId, slot, metadata)
			return true
		end

		return false
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

---getIdFromIdentifier
---@description Gets a player's server ID from their identifier
---@param identifier string The player's identifier
---@return number|boolean Server ID or false if not found
---@public
function bridge:getIdFromIdentifier(identifier)
	if not identifier then
		return false
	end
	local player = self.object.GetPlayerFromIdentifier(identifier)
	if not player then
		return false
	end
	return player.source
end

---updateOfflinePlayerAccount
---@description Updates an offline player's account balance
---@param identifier string The player's identifier
---@param account string The account type (bank, money, etc.)
---@param amount number The amount to add (positive) or remove (negative)
---@return boolean Success status
---@public
function bridge:updateOfflinePlayerAccount(identifier, account, amount)
	if not identifier or not account or not amount then
		return false
	end

	local response = MySQL.query.await("SELECT * FROM `users` WHERE `identifier` = ?", { identifier })
	if #response == 0 then
		return false
	end

	local accounts = json.decode(response[1].accounts)

	if not accounts[account] then
		return false
	end

	accounts[account] = accounts[account] + amount

	local newAccounts = json.encode(accounts)

	MySQL.query("UPDATE `users` SET `accounts` = @accounts WHERE `identifier` = @identifier", {
		["@accounts"] = newAccounts,
		["@identifier"] = identifier,
	})

	return true
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

	self.object.RegisterUsableItem(itemName, function(playerId, itemName, itemData)
		callback(playerId, itemData)
	end)
end

---getSocietyMoney
---@description Gets the balance of a society/job account
---@param jobName string The job name (society identifier)
---@return number balance The society account balance, or 0 if not found
---@public
function bridge:getSocietyMoney(jobName)
	if not jobName then
		return 0
	end

	-- Try esx_society first (most common)
	if GetResourceState("esx_society") == "started" then
		local society = exports["esx_society"]:GetSociety(jobName)
		if society then
			local account = MySQL.scalar.await("SELECT money FROM addon_account_data WHERE account_name = ?", { society.account })
			return account or 0
		end
	end

	-- Try esx_addonaccount as fallback
	if GetResourceState("esx_addonaccount") == "started" then
		local account = MySQL.scalar.await("SELECT money FROM addon_account_data WHERE account_name = ?", { "society_" .. jobName })
		return account or 0
	end

	-- Try direct query to addon_account_data as last resort
	local account = MySQL.scalar.await("SELECT money FROM addon_account_data WHERE account_name = ?", { "society_" .. jobName })
	return account or 0
end

---removeSocietyMoney
---@description Removes money from a society/job account
---@param jobName string The job name (society identifier)
---@param amount number The amount to remove
---@return boolean success Whether the operation was successful
---@public
function bridge:removeSocietyMoney(jobName, amount)
	if not jobName or not amount or amount <= 0 then
		return false
	end

	-- Check if society has enough money
	local currentBalance = self:getSocietyMoney(jobName)
	if currentBalance < amount then
		return false
	end

	-- Try esx_society first (most common)
	if GetResourceState("esx_society") == "started" then
		local society = exports["esx_society"]:GetSociety(jobName)
		if society then
			TriggerEvent("esx_addonaccount:getSharedAccount", society.account, function(account)
				if account then
					account.removeMoney(amount)
				end
			end)
			return true
		end
	end

	-- Try esx_addonaccount as fallback
	if GetResourceState("esx_addonaccount") == "started" then
		TriggerEvent("esx_addonaccount:getSharedAccount", "society_" .. jobName, function(account)
			if account then
				account.removeMoney(amount)
			end
		end)
		return true
	end

	-- Try direct SQL update as last resort
	local affected = MySQL.update.await("UPDATE addon_account_data SET money = money - ? WHERE account_name = ? AND money >= ?", { amount, "society_" .. jobName, amount })
	return affected and affected > 0
end
