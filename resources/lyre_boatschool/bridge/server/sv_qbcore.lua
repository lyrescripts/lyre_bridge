local bridge = LyreBridge.bridgeCandidate("QBCORE")

---hasLicense
---Checks if a player has a specific license
---@param source number The player source
---@param licenseType string The type of license (boat)
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
		["boat"] = "boat",
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
---Grants a boat license to the player
---@param source number The player source
---@param licenseType string The type of license (boat)
---@return boolean success Whether the grant was successful
---@public
function bridge:grantLicense(source, licenseType)
	local Player = self.object.Functions.GetPlayer(source)
	if not Player then
		return false
	end

	-- License mapping for QBCore
	local licenseMap = {
		["boat"] = "boat",
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
