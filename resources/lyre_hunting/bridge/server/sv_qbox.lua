_G.bridge = _G.bridge or {}

local this = "QBOX"

_G.bridge[this] = {}

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

	local player = {}

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

	player.addItem = function(itemName, count, metadata)
		qPlayer.Functions.AddItem(itemName, count, nil, metadata)
	end

	player.addAmmo = function(ammoItem, weaponName, amount)
		-- Qbox stores ammo as a regular inventory item ("ammo-pistol", etc.).
		-- The weaponName argument is unused on Qbox but kept in the signature
		-- so the bridge stays interchangeable with the ESX one.
		qPlayer.Functions.AddItem(ammoItem, amount)
	end

	player.canCarryItem = function(itemName, count)
		-- Qbox inventory systems typically handle weight internally.
		-- Some Qbox setups don't have this function, so fallback to true.
		if qPlayer.Functions.CanCarryItem then
			return qPlayer.Functions.CanCarryItem(itemName, count or 1)
		end
		return true
	end

	player.removeItem = function(itemName, count)
		qPlayer.Functions.RemoveItem(itemName, count)
	end

	player.hasItem = function(itemName, count)
		local item = qPlayer.Functions.GetItemByName(itemName)
		if not item then
			return false
		end
		return item.amount >= (count or 1)
	end

	player.getItemCount = function(itemName)
		local item = qPlayer.Functions.GetItemByName(itemName)
		if not item then
			return 0
		end
		return item.amount
	end

	return player
end

