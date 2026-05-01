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

---removePlayerMoney
---Removes money from a player's account
---@param source number The player source
---@param accountType string The account type ("bank" or "money")
---@param amount number The amount to remove
---@return boolean success Whether the removal was successful
---@public
function bridge:removePlayerMoney(source, accountType, amount)
	local Player = self.object.Functions.GetPlayer(source)
	if not Player then
		return false
	end

	local account = accountType == "bank" and "bank" or "cash"
	local currentAmount = Player.PlayerData.money[account] or 0

	if currentAmount < amount then
		return false
	end

	Player.Functions.RemoveMoney(account, amount)
	return true
end

---getPlayerIdentifier
---Gets the player's unique identifier
---@param source number The player source
---@return string|nil identifier The player's identifier or nil if not found
---@public
function bridge:getPlayerIdentifier(source)
	local Player = self.object.Functions.GetPlayer(source)
	if not Player then
		return nil
	end
	return Player.PlayerData.citizenid
end

---getPlayerName
---Gets the player's first and last name
---@param source number The player source
---@return string|nil firstname The player's first name
---@return string|nil lastname The player's last name
---@public
function bridge:getPlayerName(source)
	local Player = self.object.Functions.GetPlayer(source)
	if not Player then
		return nil, nil
	end
	return Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname
end

---hasLicense
---Checks if a player has a specific license
---@param source number The player source
---@param licenseType string The type of license (plane, heli)
---@param cb function Callback function with result (true/false)
---@return void
---@public
function bridge:hasLicense(source, licenseType, cb)
	local Player = self.object.Functions.GetPlayer(source)
	if not Player then
		cb(false)
		return
	end

	-- License mapping for QBCore
	local licenseMap = {
		["plane"] = "fly_plane",
		["heli"] = "fly_heli",
	}

	local license = licenseMap[licenseType]
	if not license then
		cb(false)
		return
	end

	-- Check if player has the license in metadata
	local metadata = Player.PlayerData.metadata
	local hasLicense = metadata.licences and metadata.licences[license] == true
	cb(hasLicense)
end

---grantLicense
---Grants a pilot license to the player
---@param source number The player source
---@param licenseType string The type of license (plane, heli)
---@return boolean success Whether the grant was successful
---@public
function bridge:grantLicense(source, licenseType)
	local Player = self.object.Functions.GetPlayer(source)
	if not Player then
		return false
	end

	-- License mapping for QBCore
	local licenseMap = {
		["plane"] = "fly_plane",
		["heli"] = "fly_heli",
	}

	local license = licenseMap[licenseType]
	if not license then
		return false
	end

	-- Check if player already has the license
	local metadata = Player.PlayerData.metadata
	if metadata.licences and metadata.licences[license] then
		return true -- Already has license
	end

	-- Grant the license
	if not metadata.licences then
		metadata.licences = {}
	end
	metadata.licences[license] = true
	Player.Functions.SetMetaData("licences", metadata.licences)
	Player.Functions.Save()
	return true
end
