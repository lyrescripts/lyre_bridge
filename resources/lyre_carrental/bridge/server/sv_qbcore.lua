_G.bridge = _G.bridge or {}

local this = "QBCORE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return GetResourceState("qb-core") == "started"
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	self.object = exports["qb-core"]:GetCoreObject()
end

---getPlayerFromId
---@param playerId number
---@return table
---@public
function bridge:getPlayerFromId(playerId)
	local player = self.object.Functions.GetPlayer(playerId)

	if not player then
		return false
	end

	local _player = {}

	_player.showNotification = function(message)
		TriggerClientEvent("QBCore:Notify", playerId, message or "", "success", 5000)
	end

	_player.getAccount = function(account)
		if not account then
			return
		end
		local accounts = player.PlayerData.money
		if account == "money" then
			return accounts.cash
		elseif account == "bank" then
			return accounts.bank
		elseif account == "black_money" then
			return accounts.crypto
		else
			return
		end
	end

	_player.removeAccountMoney = function(account, amount)
		if not account or not amount then
			return
		end
		if account == "money" then
			player.Functions.RemoveMoney("cash", amount, "")
		elseif account == "bank" then
			player.Functions.RemoveMoney("bank", amount, "")
		elseif account == "black_money" then
			player.Functions.RemoveMoney("crypto", amount, "")
		else
			return
		end
	end

	_player.addAccountMoney = function(account, amount)
		if not account or not amount then
			return
		end
		if account == "money" then
			player.Functions.AddMoney("cash", amount, "")
		elseif account == "bank" then
			player.Functions.AddMoney("bank", amount, "")
		elseif account == "black_money" then
			player.Functions.AddMoney("crypto", amount, "")
		else
			return
		end
	end

	return _player
end
