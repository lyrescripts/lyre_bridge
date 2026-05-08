_G.bridge = _G.bridge or {}

local this = "ESX"

_G.bridge[this] = {}

_G.bridge[this].autoDetect = function()
	return LyreBridge.isStarted("es_extended")
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

---getAccount
---@param accountName string
---@return number
---@public
function bridge:getAccount(accountName)
	local playerData = self.object.GetPlayerData()

	local _return = 0

	if playerData.accounts then
		for i = 1, #playerData.accounts, 1 do
			if playerData.accounts[i].name == accountName then
				_return = playerData.accounts[i].money
				break
			end
		end
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
