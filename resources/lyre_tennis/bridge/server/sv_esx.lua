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

---getPlayerStats
---@param identifier string
---@return table
---@public
function bridge:getPlayerStats(identifier)
	local result = MySQL.single.await(
		[[
		SELECT * FROM lyre_tennis_players WHERE identifier = ?
	]],
		{ identifier }
	)

	if result then
		return {
			elo = result.elo or 0,
			eloPeak = result.elo_peak or 0,
			matchesPlayed = result.matches_played or 0,
			matchesWon = result.matches_won or 0,
			matchesLost = result.matches_lost or 0,
			pointsWon = result.points_won or 0,
			gamesWon = result.games_won or 0,
			gamesLost = result.games_lost or 0,
			setsWon = result.sets_won or 0,
			setsLost = result.sets_lost or 0,
			aces = result.aces or 0,
			doubleFaults = result.double_faults or 0,
			winstreak = result.winstreak or 0,
			winstreakMax = result.winstreak_max or 0,
		}
	else
		return {
			elo = 0,
			eloPeak = 0,
			matchesPlayed = 0,
			matchesWon = 0,
			matchesLost = 0,
			pointsWon = 0,
			gamesWon = 0,
			gamesLost = 0,
			setsWon = 0,
			setsLost = 0,
			aces = 0,
			doubleFaults = 0,
			winstreak = 0,
			winstreakMax = 0,
		}
	end
end

---savePlayerStats
---@param identifier string
---@param name string
---@param stats table
---@param eloChange number (optional) ELO gained/lost this match for weekly/monthly tracking
---@return void
---@public
function bridge:savePlayerStats(identifier, name, stats, eloChange)
	-- Save to all-time table
	MySQL.insert.await(
		[[
		INSERT INTO lyre_tennis_players (identifier, name, elo, elo_peak, matches_played, matches_won, matches_lost,
			points_won, games_won, games_lost, sets_won, sets_lost, aces, double_faults, winstreak, winstreak_max)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON DUPLICATE KEY UPDATE
			name = VALUES(name),
			elo = VALUES(elo),
			elo_peak = VALUES(elo_peak),
			matches_played = VALUES(matches_played),
			matches_won = VALUES(matches_won),
			matches_lost = VALUES(matches_lost),
			points_won = VALUES(points_won),
			games_won = VALUES(games_won),
			games_lost = VALUES(games_lost),
			sets_won = VALUES(sets_won),
			sets_lost = VALUES(sets_lost),
			aces = VALUES(aces),
			double_faults = VALUES(double_faults),
			winstreak = VALUES(winstreak),
			winstreak_max = VALUES(winstreak_max)
	]],
		{
			identifier,
			name or "Unknown",
			stats.elo or 0,
			stats.eloPeak or 0,
			stats.matchesPlayed or 0,
			stats.matchesWon or 0,
			stats.matchesLost or 0,
			stats.pointsWon or 0,
			stats.gamesWon or 0,
			stats.gamesLost or 0,
			stats.setsWon or 0,
			stats.setsLost or 0,
			stats.aces or 0,
			stats.doubleFaults or 0,
			stats.winstreak or 0,
			stats.winstreakMax or 0,
		}
	)

	-- Save to weekly table (incremental stats)
	MySQL.insert.await(
		[[
		INSERT INTO lyre_tennis_players_weekly (identifier, name, elo_gained, matches_played, matches_won, matches_lost,
			points_won, games_won, games_lost, sets_won, sets_lost, aces, double_faults, winstreak, winstreak_max)
		VALUES (?, ?, ?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON DUPLICATE KEY UPDATE
			name = VALUES(name),
			elo_gained = elo_gained + VALUES(elo_gained),
			matches_played = matches_played + 1,
			matches_won = matches_won + VALUES(matches_won),
			matches_lost = matches_lost + VALUES(matches_lost),
			points_won = points_won + VALUES(points_won),
			games_won = games_won + VALUES(games_won),
			games_lost = games_lost + VALUES(games_lost),
			sets_won = sets_won + VALUES(sets_won),
			sets_lost = sets_lost + VALUES(sets_lost),
			aces = aces + VALUES(aces),
			double_faults = double_faults + VALUES(double_faults),
			winstreak = VALUES(winstreak),
			winstreak_max = GREATEST(winstreak_max, VALUES(winstreak_max))
	]],
		{
			identifier,
			name or "Unknown",
			eloChange or 0,
			stats.matchWon and 1 or 0,
			stats.matchLost and 1 or 0,
			stats.pointsWonThisMatch or 0,
			stats.gamesWonThisMatch or 0,
			stats.gamesLostThisMatch or 0,
			stats.setsWonThisMatch or 0,
			stats.setsLostThisMatch or 0,
			stats.acesThisMatch or 0,
			stats.doubleFaultsThisMatch or 0,
			stats.winstreak or 0,
			stats.winstreakMax or 0,
		}
	)

	-- Save to monthly table (incremental stats)
	MySQL.insert.await(
		[[
		INSERT INTO lyre_tennis_players_monthly (identifier, name, elo_gained, matches_played, matches_won, matches_lost,
			points_won, games_won, games_lost, sets_won, sets_lost, aces, double_faults, winstreak, winstreak_max)
		VALUES (?, ?, ?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON DUPLICATE KEY UPDATE
			name = VALUES(name),
			elo_gained = elo_gained + VALUES(elo_gained),
			matches_played = matches_played + 1,
			matches_won = matches_won + VALUES(matches_won),
			matches_lost = matches_lost + VALUES(matches_lost),
			points_won = points_won + VALUES(points_won),
			games_won = games_won + VALUES(games_won),
			games_lost = games_lost + VALUES(games_lost),
			sets_won = sets_won + VALUES(sets_won),
			sets_lost = sets_lost + VALUES(sets_lost),
			aces = aces + VALUES(aces),
			double_faults = double_faults + VALUES(double_faults),
			winstreak = VALUES(winstreak),
			winstreak_max = GREATEST(winstreak_max, VALUES(winstreak_max))
	]],
		{
			identifier,
			name or "Unknown",
			eloChange or 0,
			stats.matchWon and 1 or 0,
			stats.matchLost and 1 or 0,
			stats.pointsWonThisMatch or 0,
			stats.gamesWonThisMatch or 0,
			stats.gamesLostThisMatch or 0,
			stats.setsWonThisMatch or 0,
			stats.setsLostThisMatch or 0,
			stats.acesThisMatch or 0,
			stats.doubleFaultsThisMatch or 0,
			stats.winstreak or 0,
			stats.winstreakMax or 0,
		}
	)
end

---saveMatchHistory
---@param matchData table
---@return void
---@public
function bridge:saveMatchHistory(matchData)
	MySQL.insert.await(
		[[
		INSERT INTO lyre_tennis_matches (
			player1_identifier, player2_identifier, winner_identifier, match_type, match_format, final_score,
			player1_elo_before, player2_elo_before, player1_elo_change, player2_elo_change,
			player1_points, player2_points, player1_games, player2_games, player1_sets, player2_sets,
			player1_aces, player2_aces, player1_double_faults, player2_double_faults,
			team1_player1_identifier, team1_player2_identifier, team2_player1_identifier, team2_player2_identifier, winner_team,
			court_id, duration_seconds
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	]],
		{
			matchData.player1Identifier,
			matchData.player2Identifier,
			matchData.winnerIdentifier,
			matchData.matchType,
			matchData.matchFormat or "singles",
			matchData.finalScore,
			matchData.player1EloBefore,
			matchData.player2EloBefore,
			matchData.player1EloChange,
			matchData.player2EloChange,
			matchData.player1Points,
			matchData.player2Points,
			matchData.player1Games,
			matchData.player2Games,
			matchData.player1Sets,
			matchData.player2Sets,
			matchData.player1Aces,
			matchData.player2Aces,
			matchData.player1DoubleFaults,
			matchData.player2DoubleFaults,
			matchData.team1Player1Identifier,
			matchData.team1Player2Identifier,
			matchData.team2Player1Identifier,
			matchData.team2Player2Identifier,
			matchData.winnerTeam,
			matchData.courtId,
			matchData.durationSeconds,
		}
	)
end

---getLeaderboardPaginated
---@param offset number
---@param limit number
---@param period string "alltime", "weekly", or "monthly"
---@return table
---@public
function bridge:getLeaderboardPaginated(offset, limit, period)
	period = period or "alltime"

	local tableName = "lyre_tennis_players"
	local orderBy = "elo"
	local eloField = "elo"

	if period == "weekly" then
		tableName = "lyre_tennis_players_weekly"
		orderBy = "elo_gained"
		eloField = "elo_gained"
	elseif period == "monthly" then
		tableName = "lyre_tennis_players_monthly"
		orderBy = "elo_gained"
		eloField = "elo_gained"
	end

	local query = string.format(
		[[
		SELECT identifier, name, %s as elo, matches_played, matches_won
		FROM %s
		WHERE matches_played > 0
		ORDER BY %s DESC
		LIMIT ? OFFSET ?
	]],
		eloField,
		tableName,
		orderBy
	)

	local results = MySQL.query.await(query, { limit or 50, offset or 0 })

	local leaderboard = {}
	if results then
		for i, row in ipairs(results) do
			-- For weekly/monthly, we need to get the actual ELO from all-time table for rank badge
			local actualElo = row.elo
			local rankName = "None"
			local rankBadge = "badge-none.png"

			if period ~= "alltime" then
				-- Get actual ELO from all-time table for badge calculation
				local playerData = MySQL.single.await(
					[[
					SELECT elo FROM lyre_tennis_players WHERE identifier = ?
				]],
					{ row.identifier }
				)
				if playerData then
					actualElo = playerData.elo
				end
			end

			for _, rankData in ipairs(Config.ranks) do
				if actualElo >= rankData.minElo and actualElo <= rankData.maxElo then
					rankName = rankData.name
					rankBadge = rankData.badge
					break
				end
			end

			table.insert(leaderboard, {
				position = (offset or 0) + i,
				identifier = row.identifier,
				name = row.name or "Unknown",
				elo = row.elo, -- This is elo_gained for weekly/monthly
				rank = rankName,
				badge = rankBadge,
				matchesPlayed = row.matches_played,
				matchesWon = row.matches_won,
				winRate = row.matches_played > 0 and math.floor((row.matches_won / row.matches_played) * 100) or 0,
			})
		end
	end

	return leaderboard
end

---getPlayerLeaderboardPosition
---@param identifier string
---@param period string "alltime", "weekly", or "monthly"
---@return table|nil
---@public
function bridge:getPlayerLeaderboardPosition(identifier, period)
	period = period or "alltime"

	local tableName = "lyre_tennis_players"
	local orderBy = "elo"
	local eloField = "elo"

	if period == "weekly" then
		tableName = "lyre_tennis_players_weekly"
		orderBy = "elo_gained"
		eloField = "elo_gained"
	elseif period == "monthly" then
		tableName = "lyre_tennis_players_monthly"
		orderBy = "elo_gained"
		eloField = "elo_gained"
	end

	local query = string.format(
		[[
		SELECT position, %s as elo, matches_played, matches_won FROM (
			SELECT
				identifier,
				%s,
				matches_played,
				matches_won,
				ROW_NUMBER() OVER (ORDER BY %s DESC) as position
			FROM %s
			WHERE matches_played > 0
		) ranked
		WHERE identifier = ?
	]],
		eloField,
		eloField,
		orderBy,
		tableName
	)

	local result = MySQL.single.await(query, { identifier })

	if result then
		-- For weekly/monthly, get actual ELO from all-time table for badge
		local actualElo = result.elo
		if period ~= "alltime" then
			local playerData = MySQL.single.await(
				[[
				SELECT elo FROM lyre_tennis_players WHERE identifier = ?
			]],
				{ identifier }
			)
			if playerData then
				actualElo = playerData.elo
			end
		end

		local rankName = "None"
		local rankBadge = "badge-none.png"
		for _, rankData in ipairs(Config.ranks) do
			if actualElo >= rankData.minElo and actualElo <= rankData.maxElo then
				rankName = rankData.name
				rankBadge = rankData.badge
				break
			end
		end

		return {
			position = result.position,
			elo = result.elo, -- elo_gained for weekly/monthly
			rank = rankName,
			badge = rankBadge,
			matchesPlayed = result.matches_played,
			matchesWon = result.matches_won,
			winRate = result.matches_played > 0 and math.floor((result.matches_won / result.matches_played) * 100) or 0,
		}
	end

	return nil
end
