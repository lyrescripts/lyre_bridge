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

function bridge:lockpickVehicle(netVehicle, gameDifficulty)
	local vehicle = NetworkGetEntityFromNetworkId(netVehicle)
	if not DoesEntityExist(vehicle) then
		return false
	end
	local difficulty = nil
	if gameDifficulty == 1 then
		difficulty = "easy"
	elseif gameDifficulty == 2 then
		difficulty = "medium"
	elseif gameDifficulty == 3 then
		difficulty = "hard"
	end
	if not difficulty then
		return false
	end
	TaskTurnPedToFaceEntity(PlayerPedId(), vehicle, -1)
	RequestAnimDict("mini@repair")
	repeat
		Citizen.Wait(1)
	until HasAnimDictLoaded("mini@repair")
	TaskPlayAnim(PlayerPedId(), "mini@repair", "fixing_a_ped", 8.0, -8.0, -1, 49, 0, false, false, false)

	local function playCountdown()
		for i = 3, 1, -1 do
			PlaySoundFrontend(-1, "5_SEC_WARNING", "HUD_MINI_GAME_SOUNDSET", true)
			local endTime = GetGameTimer() + 1000
			while GetGameTimer() < endTime do
				SetTextFont(7) -- GTA Online uses font 7 for countdowns
				SetTextProportional(1)
				SetTextScale(0.0, 1.0) -- Adjust scale to match GTA Online
				SetTextColour(255, 255, 255, 255)
				SetTextDropshadow(0, 0, 0, 0, 255)
				SetTextEdge(1, 0, 0, 0, 255)
				SetTextDropShadow()
				SetTextOutline()
				SetTextCentre(1)
				SetTextEntry("STRING")
				AddTextComponentString(tostring(i))
				DrawText(0.5, 0.4) -- Adjust position to match GTA Online
				Citizen.Wait(0)
			end
		end
		PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
	end

	local finalResult = false
	for i = 1, 3 do
		playCountdown()
		local success = lib.skillCheck({ difficulty })

		lib.progressCircle({
			label = _U("lockpick_vehicle_progress", i, 3),
			duration = 2000,
			useWhileDead = false,
			canCancel = false,
		})

		if not success then
			break
		end

		if i == 3 then
			finalResult = true
		end
	end

	ClearPedTasks(PlayerPedId())
	return finalResult
end
