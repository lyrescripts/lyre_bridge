local bridge = LyreBridge.bridgeCandidate("ESX")

---placeExplosive
---@param target number
---@return void
---@public
function bridge:placeExplosive(target)
	local playerPed = PlayerPedId()
	if not DoesEntityExist(target) then
		return
	end

	TaskTurnPedToFaceEntity(playerPed, target, -1)

	local dict = "weapons@first_person@aim_idle@p_m_zero@projectile@misc@thermal_charge@fidgets@a"
	local anim = "fidget_med_loop"

	RequestAnimDict(dict)
	local animAttempts = 0
	repeat
		Citizen.Wait(1)
		animAttempts = animAttempts + 1
	until HasAnimDictLoaded(dict) or animAttempts >= 500

	if not HasAnimDictLoaded(dict) then
		return false
	end

	TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)

	local x, y, z = table.unpack(GetEntityCoords(playerPed))
	RequestModel("prop_c4_final")
	local modelAttempts = 0
	repeat
		Citizen.Wait(1)
		modelAttempts = modelAttempts + 1
	until HasModelLoaded("prop_c4_final") or modelAttempts >= 500

	if not HasModelLoaded("prop_c4_final") then
		ClearPedTasks(playerPed)
		return false
	end

	local prop = CreateObject(GetHashKey("prop_c4_final"), x, y, z + 0.2, true, true, true)
	AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, 28422), 0.12, 0.0, 0.0, 100.0, 50.0, 60.0, true, true, false, true, 1, true)

	local function playCountdown()
		for i = 3, 1, -1 do
			PlaySoundFrontend(-1, "5_SEC_WARNING", "HUD_MINI_GAME_SOUNDSET", true)
			local endTime = GetGameTimer() + 1000
			while GetGameTimer() < endTime do
				SetTextFont(7)
				SetTextProportional(1)
				SetTextScale(0.0, 1.0)
				SetTextColour(255, 255, 255, 255)
				SetTextDropshadow(0, 0, 0, 0, 255)
				SetTextEdge(1, 0, 0, 0, 255)
				SetTextDropShadow()
				SetTextOutline()
				SetTextCentre(1)
				SetTextEntry("STRING")
				AddTextComponentString(tostring(i))
				DrawText(0.5, 0.4)
				Citizen.Wait(0)
			end
		end
		PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
	end

	local finalResult = false
	for i = 1, 3 do
		playCountdown()
		local success = lib.skillCheck({ "easy" })

		lib.progressCircle({
			label = _U("progress_explosive_placing", i, 3),
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
	DeleteEntity(prop)
	SetModelAsNoLongerNeeded("prop_c4_final")
	return finalResult
end

---grabMoney
---@param target number
---@param bagNumber number
---@param onCancel function
---@return void
---@public
function bridge:grabMoney(target, bagNumber, onCancel)
	local playerPed = PlayerPedId()

	TaskTurnPedToFaceEntity(playerPed, target, -1)

	local dict = "anim@heists@ornate_bank@grab_cash"
	local anim = "grab"

	RequestAnimDict(dict)
	local animAttempts = 0
	repeat
		Citizen.Wait(1)
		animAttempts = animAttempts + 1
	until HasAnimDictLoaded(dict) or animAttempts >= 500

	if not HasAnimDictLoaded(dict) then
		return
	end

	TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)

	if lib.progressCircle({
		label = _U("progress_grab_money", bagNumber, Config.timeToGrabMoney),
		duration = 1000,
		useWhileDead = false,
		canCancel = true,
	}) then
	else
		onCancel()
	end

	PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
	ClearPedTasks(playerPed)
end
