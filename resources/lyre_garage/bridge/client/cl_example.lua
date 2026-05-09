local bridge = LyreBridge.bridgeCandidate("EXAMPLE")

function bridge:autoDetect()
    -- Customize this function
    return false
end

---init
---@return void
---@public
function bridge:init()
	-- Customize this function, this function is executed when the bridge is detected. You can for example set self.object to the shared object of your framework.
end

---applyVehicleProperties
---@param vehicle number
---@param properties table
---@return void
---@public
function bridge:applyVehicleProperties(vehicle, properties)
	-- Edit this function to match your framework's functions

	-- VehicleDeformation integration
	if LyreBridge.isStarted("VehicleDeformation") then
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
	-- Edit this function to match your framework's functions
	local properties = {}

	-- VehicleDeformation integration
	if LyreBridge.isStarted("VehicleDeformation") then
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
	-- Edit this function to match your framework's functions
	return { name = "police", grade = 2 }
end

---getPlayerGang
---@return table|nil
---@public
function bridge:getPlayerGang()
	-- Edit this function to match your framework's functions
	return { name = "ballas", grade = 1 }
end

---isPlayerOnJobDuty
---@return boolean
---@public
function bridge:isPlayerOnJobDuty()
	-- Edit this function to match your framework's functions
	return true
end

---isPlayerOnGangDuty
---@return boolean
---@public
function bridge:isPlayerOnGangDuty()
	-- Edit this function to match your framework's functions
	return true
end
