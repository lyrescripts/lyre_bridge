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

---applyVehicleProperties
---@param vehicle number
---@param properties table
---@return void
---@public
function bridge:applyVehicleProperties(vehicle, properties)
	self.object.Game.SetVehicleProperties(vehicle, properties)

	-- VehicleDeformation integration
	if GetResourceState("VehicleDeformation") == "started" then
		local deformation = properties["lyre_garage-deformation"]
		if deformation then
			exports["VehicleDeformation"]:SetVehicleDeformation(vehicle, deformation)
		end
	end
end

---getVehicleProperties
---@param vehicle number
---@return table
---@public
function bridge:getVehicleProperties(vehicle)
	local properties = self.object.Game.GetVehicleProperties(vehicle)

	-- VehicleDeformation integration
	if GetResourceState("VehicleDeformation") == "started" then
		local deformation = exports["VehicleDeformation"]:GetVehicleDeformation(vehicle)
		if deformation then
			properties["lyre_garage-deformation"] = deformation
		end
	end

	return properties
end

---getPlayerJob
---@return table|nil
---@public
function bridge:getPlayerJob()
	if not self.object then
		return nil
	end
	local playerData = self.object.GetPlayerData()
	if not playerData or not playerData.job then
		return nil
	end
	return playerData.job
end

---getPlayerGang
---@return table|nil
---@public
function bridge:getPlayerGang()
	-- Customize this function to match your framework's gang system
	return { name = "ballas", grade = 1 }
end

---isPlayerOnJobDuty
---@return boolean
---@public
function bridge:isPlayerOnJobDuty()
	-- Customize this function to match your framework's duty system
	-- Example: return YourFramework.GetPlayerData().job.onduty or false
	return true
end

---isPlayerOnGangDuty
---@return boolean
---@public
function bridge:isPlayerOnGangDuty()
	-- Customize this function to match your framework's duty system
	-- Example: return YourFramework.GetPlayerData().gang.onduty or false
	return true
end
