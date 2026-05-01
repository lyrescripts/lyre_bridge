_G.bridge = _G.bridge or {}

local this = "QBCORE"

_G.bridge[this] = {}
_G.bridge[this].supportsItemMetadata = true

_G.bridge[this].autoDetect = function()
	return GetResourceState("qb-core") == "started"
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@description Initializes the QBCore bridge
---@return void
---@public
function bridge:init()
	self.object = exports["qb-core"]:GetCoreObject()
end

---getPlayerFromId
---@description Gets a player object with helper methods from their server ID
---@param playerId number The player's server ID
---@return table|boolean Player object with methods or false if not found
---@public
function bridge:getPlayerFromId(playerId)
	local qPlayer = self.object.Functions.GetPlayer(playerId)

	if not qPlayer then
		return false
	end

	local player = {}

	player.getIdentifier = function()
		return qPlayer.PlayerData.citizenid
	end

	player.showNotification = function(message)
		TriggerClientEvent("QBCore:Notify", playerId, message)
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

	player.addItem = function(itemName, count, metadata)
		if GetResourceState("ox_inventory") == "started" then
			exports.ox_inventory:AddItem(playerId, itemName, count, metadata)
			return
		end

		qPlayer.Functions.AddItem(itemName, count, nil, metadata)
	end

	player.removeItem = function(itemName, count, slot)
		if GetResourceState("ox_inventory") == "started" then
			exports.ox_inventory:RemoveItem(playerId, itemName, count, nil, slot)
			return
		end

		qPlayer.Functions.RemoveItem(itemName, count, slot)
	end

	player.getItemCount = function(itemName)
		if GetResourceState("ox_inventory") == "started" then
			local success, count = pcall(function()
				return exports.ox_inventory:Search(playerId, "count", itemName)
			end)

			return success and (count or 0) or 0
		end

		local item = qPlayer.Functions.GetItemByName(itemName)
		return item and (item.amount or item.count) or 0
	end

	player.setItemMetadata = function(itemName, slot, metadata)
		slot = tonumber(slot)
		if not slot or not qPlayer.PlayerData.items or not qPlayer.PlayerData.items[slot] then
			return false
		end

		if qPlayer.PlayerData.items[slot].name ~= itemName then
			return false
		end

		qPlayer.PlayerData.items[slot].info = metadata
		qPlayer.Functions.SetInventory(qPlayer.PlayerData.items)
		return true
	end

	player.getAdminRank = function()
		local permissions = bridge.object.Functions.GetPermission(playerId)
		return permissions
	end

	return player
end

---getIdFromIdentifier
---@description Gets a player's server ID from their identifier
---@param identifier string The player's citizen ID
---@return number|boolean Server ID or false if not found
---@public
function bridge:getIdFromIdentifier(identifier)
	if not identifier then
		return false
	end
	local player = self.object.Functions.GetPlayerByCitizenId(identifier)
	if not player then
		return false
	end
	return player.PlayerData.source
end

---updateOfflinePlayerAccount
---@description Updates an offline player's account balance
---@param identifier string The player's citizen ID
---@param account string The account type (bank, money, etc.)
---@param amount number The amount to add (positive) or remove (negative)
---@return boolean Success status
---@public
function bridge:updateOfflinePlayerAccount(identifier, account, amount)
	if not identifier or not account or not amount then
		return false
	end

	local moneyColumn = "bank"
	if account == "money" then
		moneyColumn = "cash"
	elseif account == "black_money" then
		moneyColumn = "crypto"
	end

	local response = MySQL.query.await("SELECT * FROM `players` WHERE `citizenid` = ?", { identifier })
	if #response == 0 then
		return false
	end

	local money = json.decode(response[1].money)

	if not money[moneyColumn] then
		money[moneyColumn] = 0
	end

	money[moneyColumn] = money[moneyColumn] + amount

	local newMoney = json.encode(money)

	MySQL.query("UPDATE `players` SET `money` = @money WHERE `citizenid` = @citizenid", {
		["@money"] = newMoney,
		["@citizenid"] = identifier,
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

	self.object.Functions.CreateUseableItem(itemName, function(source, item)
		callback(source, item)
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

	-- Try qb-management first (most common for QB-Core)
	if GetResourceState("qb-management") == "started" then
		local result = exports["qb-management"]:GetAccount(jobName)
		return result or 0
	end

	-- Try qb-banking as fallback
	if GetResourceState("qb-banking") == "started" then
		local result = exports["qb-banking"]:GetAccountBalance(jobName)
		return result or 0
	end

	-- Try direct query to management tables as last resort
	local result = MySQL.scalar.await("SELECT amount FROM management_funds WHERE job_name = ?", { jobName })
	return result or 0
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

	-- Try qb-management first (most common for QB-Core)
	if GetResourceState("qb-management") == "started" then
		local success = exports["qb-management"]:RemoveMoney(jobName, amount)
		return success ~= false
	end

	-- Try qb-banking as fallback
	if GetResourceState("qb-banking") == "started" then
		local success = exports["qb-banking"]:RemoveMoney(jobName, amount, "Society payment for fuel")
		return success ~= false
	end

	-- Try direct SQL update as last resort
	local affected = MySQL.update.await("UPDATE management_funds SET amount = amount - ? WHERE job_name = ? AND amount >= ?", { amount, jobName, amount })
	return affected and affected > 0
end
