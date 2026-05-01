_G.bridge = _G.bridge or {}

local this = "EXAMPLE"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	-- Customize this function
	return false
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	-- Customize this function, this function is executed when the bridge is detected. You can for example set self.object to the shared object of your framework.
end

---removePlayerMoney
---Removes money from a player's account
---@param source number The player source
---@param accountType string The account type ("bank" or "money")
---@param amount number The amount to remove
---@return boolean success Whether the removal was successful
---@public
function bridge:removePlayerMoney(source, accountType, amount)
	-- Customize this function
	return false
end

---getPlayerIdentifier
---Gets the player's unique identifier
---@param source number The player source
---@return string|nil identifier The player's identifier or nil if not found
---@public
function bridge:getPlayerIdentifier(source)
	-- Customize this function
	return nil
end

---getPlayerName
---Gets the player's first and last name
---@param source number The player source
---@return string|nil firstname The player's first name
---@return string|nil lastname The player's last name
---@public
function bridge:getPlayerName(source)
	-- Customize this function
	return nil, nil
end

---hasLicense
---Checks if a player has a specific license
---@param source number The player source
---@param licenseType string The type of license (car, motorcycle, truck)
---@param cb function Callback function with result (true/false)
---@return void
---@public
function bridge:hasLicense(source, licenseType, cb)
	-- Customize this function
	cb(false)
end

---grantLicense
---Grants a driving license to the player
---@param source number The player source
---@param licenseType string The type of license (car, motorcycle, truck)
---@return boolean success Whether the grant was successful
---@public
function bridge:grantLicense(source, licenseType)
	-- Customize this function
	return true
end
