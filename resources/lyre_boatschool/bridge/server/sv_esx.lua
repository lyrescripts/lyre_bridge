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

---removePlayerMoney
---Removes money from a player's account
---@param source number The player source
---@param accountType string The account type ("bank" or "money")
---@param amount number The amount to remove
---@return boolean success Whether the removal was successful
---@public
function bridge:removePlayerMoney(source, accountType, amount)
	local xPlayer = self.object.GetPlayerFromId(source)
	if not xPlayer then
		return false
	end

	local account = accountType == "bank" and "bank" or "money"
	local currentAmount = xPlayer.getAccount(account).money

	if currentAmount < amount then
		return false
	end

	xPlayer.removeAccountMoney(account, amount)
	return true
end

---getPlayerIdentifier
---Gets the player's unique identifier
---@param source number The player source
---@return string|nil identifier The player's identifier or nil if not found
---@public
function bridge:getPlayerIdentifier(source)
	local xPlayer = self.object.GetPlayerFromId(source)
	if not xPlayer then
		return nil
	end
	return xPlayer.getIdentifier()
end

---getPlayerName
---Gets the player's first and last name
---@param source number The player source
---@return string|nil firstname The player's first name
---@return string|nil lastname The player's last name
---@public
function bridge:getPlayerName(source)
	local xPlayer = self.object.GetPlayerFromId(source)
	if not xPlayer then
		return nil, nil
	end
	return xPlayer.get("firstName"), xPlayer.get("lastName")
end

---hasLicense
---Checks if a player has a specific license
---@param source number The player source
---@param licenseType string The type of license (boat)
---@param cb function Callback function with result (true/false)
---@return void
---@public
function bridge:hasLicense(source, licenseType, cb)
	local xPlayer = self.object.GetPlayerFromId(source)
	if not xPlayer then
		cb(false)
		return
	end

	-- License mapping for ESX
	local licenseMap = {
		["boat"] = "boat",
	}

	local license = licenseMap[licenseType]
	if not license then
		cb(false)
		return
	end

	-- Check if player has the license using esx_license callback
	TriggerEvent('esx_license:checkLicense', source, license, function(result)
		cb(result)
	end)
end

---grantLicense
---Grants a boat license to the player
---@param source number The player source
---@param licenseType string The type of license (boat)
---@return boolean success Whether the grant was successful
---@public
function bridge:grantLicense(source, licenseType)
	local xPlayer = self.object.GetPlayerFromId(source)
	if not xPlayer then
		return false
	end

	-- License mapping for ESX
	local licenseMap = {
		["boat"] = "boat",
	}

	local license = licenseMap[licenseType]
	if not license then
		return false
	end

	-- Check if player already has the license using esx_license callback
	local hasLicense = false
	TriggerEvent('esx_license:checkLicense', source, license, function(result)
		hasLicense = result
	end)

	if hasLicense then
		return true -- Already has license
	end

	-- Grant the license using esx_license event
	TriggerEvent('esx_license:addLicense', source, license)
	return true
end
