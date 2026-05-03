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

	player.addItem = function(itemName, count, metadata)
		if GetResourceState("ox_inventory") == "started"
			or GetResourceState("qs-inventory") == "started" then
			xPlayer.addInventoryItem(itemName, count, metadata)
		else
			xPlayer.addWeapon(itemName, 100)
		end
	end

	player.addAmmo = function(ammoItem, weaponName, amount)
		if GetResourceState("ox_inventory") == "started"
			or GetResourceState("qs-inventory") == "started" then
			xPlayer.addInventoryItem(ammoItem, amount)
		else
			xPlayer.addWeaponAmmo(weaponName, amount)
		end
	end

	player.canCarryItem = function(itemName, count)
		-- ox_inventory and qs-inventory handle weight internally.
		-- If canCarryItem is not available (vanilla ESX without weight), return true.
		if xPlayer.canCarryItem then
			return xPlayer.canCarryItem(itemName, count or 1)
		end
		return true
	end

	player.removeItem = function(itemName, count)
		xPlayer.removeInventoryItem(itemName, count)
	end

	player.hasItem = function(itemName, count)
		local item = xPlayer.getInventoryItem(itemName)
		if not item then
			return false
		end
		return item.count >= (count or 1)
	end

	player.getItemCount = function(itemName)
		local item = xPlayer.getInventoryItem(itemName)
		if not item then
			return 0
		end
		return item.count
	end

	return player
end

