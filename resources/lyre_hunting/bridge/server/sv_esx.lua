local bridge = LyreBridge.bridgeCandidate("ESX")

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
		if type(itemName) == "string" and itemName:sub(1, 7) == "weapon_" and xPlayer.addWeapon then
			xPlayer.addWeapon(itemName, 100)
		else
			xPlayer.addInventoryItem(itemName, count, metadata)
		end
	end

	player.addAmmo = function(ammoItem, weaponName, amount)
		if weaponName and xPlayer.addWeaponAmmo then
			xPlayer.addWeaponAmmo(weaponName, amount)
		else
			xPlayer.addInventoryItem(ammoItem, amount)
		end
	end

	player.canCarryItem = function(itemName, count)
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
