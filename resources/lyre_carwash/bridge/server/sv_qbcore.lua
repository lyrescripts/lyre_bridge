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


---updateOfflinePlayerAccount
---@param identifier string
---@param account string
---@param amount number
---@return void
---@public
function bridge:updateOfflinePlayerAccount(identifier, account, amount)
	if not identifier then
		return
	end
	if not account then
		return
	end
	if not amount then
		return
	end

	local response = MySQL.query.await("SELECT * FROM `players` WHERE `citizenid` = ?", { identifier })
	if #response == 0 then
		return false
	end

	local accounts = json.decode(response[1].money) or {}

	local accountMoney = accounts["cash"] or 0
	local accountBank = accounts["bank"] or 0
	local accountDirty = accounts["crypto"] or 0

	if account == "money" then
		accountMoney = accountMoney + amount
	elseif account == "bank" then
		accountBank = accountBank + amount
	elseif account == "black_money" then
		accountDirty = accountDirty + amount
	else
		return false
	end

	accounts["cash"] = accountMoney
	accounts["bank"] = accountBank
	accounts["crypto"] = accountDirty

	MySQL.query("UPDATE `players` SET `money` = @money WHERE `citizenid` = @citizenid", {
		["@money"] = json.encode(accounts),
		["@citizenid"] = identifier,
	})

	return true
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
