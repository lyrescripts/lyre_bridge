local bridge = LyreBridge.bridgeCandidate("QBCORE")

---getPlayerJob
---@description Gets the player's current job
---@return table|nil job The job data {name, label, grade, grade_name, grade_label} or nil if unemployed/no job
---@public
function bridge:getPlayerJob()
	local playerData = self.object.Functions.GetPlayerData()
	if not playerData or not playerData.job then
		return nil
	end

	local job = playerData.job

	-- Return nil if player is unemployed (no society account)
	if job.name == "unemployed" then
		return nil
	end

	return {
		name = job.name,
		label = job.label,
		grade = job.grade and job.grade.level or 0,
		grade_name = job.grade and job.grade.name or "",
		grade_label = job.grade and job.grade.name or "",
	}
end
