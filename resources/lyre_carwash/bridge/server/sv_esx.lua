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
---@return void
---@public
function bridge:init()
	self.object = exports["es_extended"]:getSharedObject()
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
