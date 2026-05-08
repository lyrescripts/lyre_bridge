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

---getPlayerFromId
---@param playerId number
---@return table
---@public
function bridge:getPlayerFromId(playerId)
	-- Edit this function to match your framework's functions

	local player = {}

	player.getIdentifier = function() end

	player.getName = function() end

	player.showNotification = function(message) end

	player.getAccount = function(account) end

	player.removeAccountMoney = function(account, amount) end

	player.addAccountMoney = function(account, amount) end

	player.getJob = function() end

	player.getJobRank = function() end

	player.getGang = function()
		return "ballas"
	end

	player.getGangRank = function()
		return 0
	end

	player.getAdminRank = function() end

	return player
end

---isVehicleOwned
---@param plate string
---@return boolean
---@public
function bridge:isVehicleOwned(plate)
	-- Edit this function to match your framework's functions
end

---retrieveVehicles
---@param type string
---@param owner string
---@return table
---@public
function bridge:retrieveVehicles(type, owner)
	-- Edit this function to match your framework's functions
end

---checkVehicleOwnership
---@param plate string
---@param owner string
---@return boolean
---@public
function bridge:checkVehicleOwnership(plate, owner)
	-- Edit this function to match your framework's functions
end

---getVehicleOwner
---@param plate string
---@return string|nil
---@public
function bridge:getVehicleOwner(plate)
	-- Edit this function to match your framework's functions
end

---changeVehicleOwner
---@param plate string
---@param newOwner string
---@param newOwnerType string
---@return boolean, string|nil
---@public
function bridge:changeVehicleOwner(plate, newOwner, newOwnerType)
	-- Edit this function to match your framework's functions
end

---applyVehicleProperties
---@param plate string
---@param vehicleProperties table
---@return void
---@public
function bridge:saveVehicleProperties(plate, vehicleProperties)
	-- Edit this function to match your framework's functions
end

---getVehicleName
---@param plate string
---@return string|nil
---@public
function bridge:getVehicleName(plate)
	-- Edit this function to match your framework's functions
end

---saveVehicleName
---@param plate string
---@param name string
---@return void
---@public
function bridge:saveVehicleName(plate, name)
	-- Edit this function to match your framework's functions
end

---saveVehicleLocation
---@param plate string
---@param location string
---@param locationName string
---@param callback function|nil
---@return void
---@public
function bridge:saveVehicleLocation(plate, location, locationName, callback)
	-- Edit this function to match your framework's functions
	if callback then
		callback()
	end
end

---clearVehicleLocation
---@param plate string
---@return void
---@public
function bridge:clearVehicleLocation(plate)
	-- Edit this function to match your framework's functions
end

---saveVehicleImpoundData
---@param plate string
---@param impoundData table
---@return void
---@public
function bridge:saveVehicleImpoundData(plate, impoundData)
	-- Edit this function to match your framework's functions
end

---clearVehicleImpoundData
---@param plate string
---@return void
---@public
function bridge:clearVehicleImpoundData(plate)
	-- Edit this function to match your framework's functions
end

---saveVehicleOwnerType
---@param plate string
---@param isJobVehicle boolean
---@param isGangVehicle boolean
---@param jobRank number|nil
---@param gangRank number|nil
---@return void
---@public
function bridge:saveVehicleOwnerType(plate, isJobVehicle, isGangVehicle, jobRank, gangRank)
	-- Edit this function to match your framework's functions
end

---saveVehicleFuel
---@param plate string
---@param fuel number
---@return void
---@public
function bridge:saveVehicleFuel(plate, fuel)
	-- Edit this function to match your framework's functions
end

---getVehicleLocationName
---@param plate string
---@return string|nil
---@public
function bridge:getVehicleLocationName(plate)
	-- Edit this function to match your framework's functions
end

---getVehicleJobRank
---@param plate string
---@return number
---@public
function bridge:getVehicleJobRank(plate)
	-- Edit this function to match your framework's functions
end

---getVehicleGangRank
---@param plate string
---@return number
---@public
function bridge:getVehicleGangRank(plate)
	-- Edit this function to match your framework's functions
end

---countPlayerVehiclesInGarage
---@param owner string
---@param garageId string
---@param excludePlate string|nil
---@param callback function
---@return void
---@public
function bridge:countPlayerVehiclesInGarage(owner, garageId, excludePlate, callback)
	-- Edit this function to match your framework's functions
end

---countAllVehiclesInGarage
---@param garageId string
---@param excludePlate string|nil
---@param callback function
---@return void
---@public
function bridge:countAllVehiclesInGarage(garageId, excludePlate, callback)
	-- Edit this function to match your framework's functions
end

---giveVehicle
---@param owner string The owner identifier (player identifier, job name, or gang name)
---@param vehicleModel string
---@param plate string
---@param isJobVehicle boolean
---@param isGangVehicle boolean
---@param callback function
---@return void
---@public
function bridge:giveVehicle(owner, vehicleModel, plate, isJobVehicle, isGangVehicle, callback)
	-- Edit this function to match your framework's functions
end

---checkPlateExists
---@param plate string
---@param callback function
---@return void
---@private
function bridge:checkPlateExists(plate, callback)
	-- Edit this function to match your framework's functions
end

---generateRandomPlate
---@return string
---@private
function bridge:generateRandomPlate()
	local plateFormat = Config.PlateFormat
	if type(plateFormat) == "string" and plateFormat ~= "" then
		local plate = ""
		local nextCharacterIsFixed = false

		for i = 1, #plateFormat do
			local character = string.sub(plateFormat, i, i)

			if nextCharacterIsFixed then
				plate = plate .. character
				nextCharacterIsFixed = false
			elseif character == "^" then
				nextCharacterIsFixed = true
			elseif character == "A" then
				plate = plate .. string.char(math.random(65, 90))
			elseif string.match(character, "%d") then
				plate = plate .. tostring(math.random(0, 9))
			else
				plate = plate .. character
			end

			if string.len(plate) >= 8 then
				break
			end
		end

		if plate ~= "" then
			return string.upper(string.sub(plate, 1, 8))
		end
	end

	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local plate = ""

	for i = 1, 8 do
		local randIndex = math.random(1, #chars)
		plate = plate .. string.sub(chars, randIndex, randIndex)
	end

	return plate
end

---getSpawnedVehicleCount
---@param garageId string
---@param model string
---@param garageType string
---@return number
---@public
function bridge:getSpawnedVehicleCount(garageId, model, garageType)
	-- Use in-memory tracking for spawn garages (server-side only, resets on restart)
	if garageType == "job" then
		if jobSpawnedVehicles[garageId] and jobSpawnedVehicles[garageId][model] then
			return jobSpawnedVehicles[garageId][model]
		end
	elseif garageType == "gang" then
		if gangSpawnedVehicles[garageId] and gangSpawnedVehicles[garageId][model] then
			return gangSpawnedVehicles[garageId][model]
		end
	end
	return 0
end

---incrementSpawnedVehicleCount
---@param garageId string
---@param model string
---@param garageType string
---@return void
---@public
function bridge:incrementSpawnedVehicleCount(garageId, model, garageType)
	-- Use in-memory tracking for spawn garages (server-side only, resets on restart)
	if garageType == "job" then
		if not jobSpawnedVehicles[garageId] then
			jobSpawnedVehicles[garageId] = {}
		end
		if not jobSpawnedVehicles[garageId][model] then
			jobSpawnedVehicles[garageId][model] = 0
		end
		jobSpawnedVehicles[garageId][model] = jobSpawnedVehicles[garageId][model] + 1
	elseif garageType == "gang" then
		if not gangSpawnedVehicles[garageId] then
			gangSpawnedVehicles[garageId] = {}
		end
		if not gangSpawnedVehicles[garageId][model] then
			gangSpawnedVehicles[garageId][model] = 0
		end
		gangSpawnedVehicles[garageId][model] = gangSpawnedVehicles[garageId][model] + 1
	end
end

---decrementSpawnedVehicleCount
---@param garageId string
---@param model string
---@param garageType string
---@return void
---@public
function bridge:decrementSpawnedVehicleCount(garageId, model, garageType)
	-- Use in-memory tracking for spawn garages (server-side only, resets on restart)
	if garageType == "job" then
		if jobSpawnedVehicles[garageId] and jobSpawnedVehicles[garageId][model] then
			jobSpawnedVehicles[garageId][model] = math.max(0, jobSpawnedVehicles[garageId][model] - 1)
		end
	elseif garageType == "gang" then
		if gangSpawnedVehicles[garageId] and gangSpawnedVehicles[garageId][model] then
			gangSpawnedVehicles[garageId][model] = math.max(0, gangSpawnedVehicles[garageId][model] - 1)
		end
	end
end

---deleteVehicleFromFramework
---@param plate string
---@param callback function
---@return void
---@public
function bridge:deleteVehicleFromFramework(plate, callback)
	-- Edit this function to match your framework's functions
end

---onImpoundPayment
---@param playerId number
---@param amount number
---@param paymentMethod string
---@param plate string
---@param impoundId string
---@return void
---@public
function bridge:onImpoundPayment(playerId, amount, paymentMethod, plate, impoundId)
	-- Manage with your framework function if you want to transfer money to society accounts
end

---onVehicleTransferPayment
---@param playerId number
---@param amount number
---@param paymentMethod string
---@param plate string
---@param targetGarageId string
---@return void
---@public
function bridge:onVehicleTransferPayment(playerId, amount, paymentMethod, plate, targetGarageId)
	-- Manage with your framework function if you want to transfer money to society accounts
end

---getVehicleInfo
---@param plate string
---@return table|nil
---@public
function bridge:getVehicleInfo(plate)
	-- Edit this function to match your framework's functions
end

---changePlate
---@param oldPlate string
---@param newPlate string
---@param callback function
---@return void
---@public
function bridge:changePlate(oldPlate, newPlate, callback)
	-- Edit this function to match your framework's functions
end

---getPlayerFromIdentifier
---@param identifier string
---@return table|nil
---@public
function bridge:getPlayerFromIdentifier(identifier)
	-- Edit this function to match your framework's functions
end

---getImpoundedVehicleData
---@param plate string
---@return table|nil
---@public
function bridge:getImpoundedVehicleData(plate)
	-- Edit this function to match your framework's functions
end

---isVehicleLockedImpound
---@param plate string
---@return boolean
---@public
function bridge:isVehicleLockedImpound(plate)
	-- Edit this function to match your framework's functions
end

---unlockImpoundedVehicle
---@param plate string
---@return boolean
---@public
function bridge:unlockImpoundedVehicle(plate)
	-- Edit this function to match your framework's functions
end

---retrieveAllImpoundedVehicles
---@param impoundId string|nil Optional impound ID to filter by (if uniqueImpound is enabled)
---@return table
---@public
function bridge:retrieveAllImpoundedVehicles(impoundId)
	-- Edit this function to match your framework's functions
	-- Should return a table of all impounded vehicles with the following fields:
	-- plate, name, vehicle (props), location, locationId, impoundFee, allowOwnerRetrieve,
	-- impoundMinRetrieveDate, impoundReason, impoundedBy, ownerIdentifier, ownerName,
	-- isJobVehicle, isGangVehicle
	return {}
end

---removeImpoundDateRestriction
---@param plate string
---@return boolean
---@public
function bridge:removeImpoundDateRestriction(plate)
	-- Edit this function to match your framework's functions
	-- Should remove the minimum retrieve date restriction from an impounded vehicle
	return false
end

---onVehicleDelete
---@param vehicle number The vehicle entity to be deleted
---@return void
---@public
---@description This function is called BEFORE a vehicle is deleted from the world.
---             It handles AdvancedParking integration if the resource is started.
function bridge:onVehicleDelete(vehicle)
	if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
		return
	end

	-- AdvancedParking integration
	if LyreBridge.isStarted("AdvancedParking") then
		exports["AdvancedParking"]:DeleteVehicle(vehicle)
	end
end

---getSharedAccessList
---@param plate string
---@return table
---@public
function bridge:getSharedAccessList(plate)
	-- Edit this function to match your framework's functions
end

---retrievePlayerImpoundedVehicles
---@param playerIdentifier string
---@param jobName string|nil
---@param gangName string|nil
---@return table
---@public
---@description Retrieves all impounded vehicles for a player in a single optimized query (personal + job + gang)
function bridge:retrievePlayerImpoundedVehicles(playerIdentifier, jobName, gangName)
	-- Edit this function to match your framework's functions
	-- Should return a table of impounded vehicles with the following fields:
	-- plate, name, vehicle (props), location, locationId, impoundFee, allowOwnerRetrieve,
	-- impoundMinRetrieveDate, impoundReason, impoundedBy, isJobVehicle, isGangVehicle, fuel
	return {}
end
