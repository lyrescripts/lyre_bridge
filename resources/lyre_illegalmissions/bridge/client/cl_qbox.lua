_G.bridge = _G.bridge or {}

local this = "QBOX"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("qbx_core")
end

local bridge = _G.bridge[this]

--[[
	BRIDGE FUNCTIONS
]]

---init
---@return void
---@public
function bridge:init()
	self.object = exports["qbx_core"]
end

---getAccount
---@param accountName string
---@return number
---@public
function bridge:getAccount(accountName)
	local playerData = self.object:GetPlayerData()

	local _return = 0

	local accounts = playerData.money

	if accounts and accountName == "money" then
		_return = accounts.cash
	elseif accounts and accountName == "bank" then
		_return = accounts.bank
	elseif accounts and accountName == "black_money" then
		_return = accounts.crypto
	end

	return _return
end

---alert
---@param jobName string
---@param coords table
---@param radius number
---@param title string
---@param description string
---@return void
---@public
function bridge:alert(jobName, coords, radius, title, description)
	self:showNotification(description)
	local alpha = 250
	local blip = AddBlipForRadius(coords.x, coords.y, coords.z, radius or 50.0)

	-- Radius blip settings
	SetBlipHighDetail(blip, true)
	SetBlipColour(blip, 1)
	SetBlipAlpha(blip, alpha)
	SetBlipAsShortRange(blip, true)

	while alpha ~= 0 do
		Citizen.Wait(500)
		alpha = alpha - 1
		SetBlipAlpha(blip, alpha)

		if alpha == 0 then
			RemoveBlip(blip)
			return
		end
	end
end
