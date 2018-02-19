

//-- Game ----------------------------------------------------------------------

game
	parent_type = /area
	icon = 'farm.dmi'
	var
		time = 1200
		// Nonconfigurable:
		gameId
		zPosition
		started = FALSE
		overtime = FALSE
		//
		list/teams = list()
		list/selectionPlayers = list()
		//
		list/placements = new()
		//
		game/hud/timer/timer
		list/scoreDisplays = new()
	proc
		setup()
			// Setup Teams
				// Create team from goals
			for(var/tile/goal/teamGoal in contents)
				var /team/newTeam = new(teamGoal.team)
				teams[newTeam.color] = newTeam
				newTeam.goal = teamGoal
				teamGoal.color = list("#fa5", newTeam.color, newTeam.color)
				// Assign farms to their closest team
			for(var/tile/farm/theFarm in contents)
				var /team/assignedTeam = assignTeam(theFarm)
				if(assignedTeam)
					assignedTeam.farms.Add(theFarm)
				// Assign Houses to their closest team
			for(var/tile/house/housePart in contents)
				var /team/assignedTeam = assignTeam(housePart)
				if(assignedTeam)
					housePart.color = list("#fa5", "#fa5", assignedTeam.color)
			for(var/tile/houseOverhang/housePart in contents)
				var /team/assignedTeam = assignTeam(housePart)
				if(assignedTeam)
					housePart.color = list("#fa5", "#fa5", assignedTeam.color)
			// Create timer
			timer = new(src)
			// Create team score displays
			for(var/teamColor in teams)
				var /game/hud/score/teamScore = new(src, teamColor)
				scoreDisplays[teamColor] = teamScore
			// Configure placement markers
			for(var/placementMarker/marker in contents)
				var positionId = "[marker.team]_[marker.position]"
				placements[positionId] = locate(marker.x, marker.y, marker.z)
				del marker

		assignTeam(atom/theAtom)
			// Determine which team closest
			var doubt = TRUE
			var /team/closeTeam
			var closeDist = 1000
			for(var/teamColor in teams)
				var /team/testTeam = teams[teamColor]
				var testDist = get_dist(testTeam.goal, theAtom)
				if(testDist < closeDist)
					closeDist = testDist
					closeTeam = testTeam
					doubt = FALSE
				else if(testDist == closeDist)
					doubt = TRUE
			// Return closest team
			if(!doubt)
				return closeTeam

		adjustScore(team, amount)
			var /team/scoreTeam = teams[team]
			scoreTeam.score += amount
			var /game/hud/score/scoreDisplay = scoreDisplays[team]
			scoreDisplay.refresh(scoreTeam.score)

		addSpectator(var/client/player)
			// Find tag "spectator_start" and place client's mob there.
			var /atom/start = locate("spectator_start")
			if(!isturf(start))
				start = locate(start.x,start.y,start.z)
			player.mob.loc = start

		addPlayer(var/client/player)
			// Spectate the player if the game has already been started.
			if(started)
				if(player)
					player << output("There is currenly a game underway. You are now being added as a spectator.", "outputChannelGame")
					addSpectator(player)
				return
			var /interface/characterSelect/selectingPlayer = new(player, src)
			selectionPlayers.Add(selectingPlayer)

		addCPU(teamColor)
			var success = addCharacter(null, teamColor)
			if(success) return success
			var /team/cpuTeam = teams[teamColor]
			for(var/character/testChar in cpuTeam.players)
				if(!istype(testChar.player, /character/rival)) continue
				var rivalIndex = cpuTeam.players.Find(testChar)
				cpuTeam.players.Cut(rivalIndex, rivalIndex+1)
				del testChar

		addCharacter(var/interface/characterSelect/player, var/teamColor as text)
			// Cancel out if invalid team
			var /team/chosenTeam = teams[teamColor]
			if(!chosenTeam)
				return
			// Determine Player Index on Team
			var /playerIndex = chosenTeam.players.len
			if(playerIndex >= 3)
				if(player)
					player << output("The [teamColor] team is full.", "outputChannelGame")
				return
			// Find start location for Player Index
			var /atom/start
			for(var/index = 1 to 3)
				// Find start for team index
				start = placements["[teamColor]_[index]"]
				// Default to start_1 if not found
				if(!start)
					hear("[__FILE__]:[__LINE__] -- Start position not located for [teamColor]_[index]")
					start = placements["[teamColor]_1"]
				// If start is free of characters, look no further
				if(!(locate(/character) in start.contents))
					playerIndex = index
					break
			if(!start)
				hear("[__FILE__]:[__LINE__] -- Start position not located for [teamColor]")
				return
			// Create gnome and attach it to player. Use AI if no user supplied
			var /character/newChar
			if(player)
				newChar = new /character/george(start)
				newChar.setTeam(teamColor, playerIndex)
				player.attachCharacter(newChar)
			else
				var gnomeType = pick(/character/george, /character/mathew, /character/glen)
				newChar = new gnomeType(start)
				newChar.setTeam(teamColor, playerIndex)
				new /character/rival(newChar)
			chosenTeam.players.Add(newChar)
			return TRUE

		/*removePlayer(var/character/who)
			var/list/team = teams[who.team]
			team.Remove(who)*/

		start()
			// Must return a TRUE value if start was successful.
			// Cancel out if the game is already under way
			if(started) return FALSE
			// Complete teams by adding AI players
			if(usr)
				var teamMax = 0
				for(var/teamColor in teams)
					var /team/theTeam = teams[teamColor]
					if(theTeam.players.len > teamMax) teamMax = theTeam.players.len
				for(var/teamColor in teams)
					var /team/theTeam = teams[teamColor]
					while(theTeam.players.len < teamMax)
						addPlayer(null, teamColor)
			// Connect players to gameplay interfaces
			for(var/interface/characterSelect/selectInt in selectionPlayers)
				new /interface/gameplay(selectInt.client, selectInt.character)
			// Sprout radishes from random farms
			for(var/tile/farm/containedFarm in src)
				if(rand(1,8) == 8)
					containedFarm.sprout()
			// Start Countdown to actual gameplay
			started = TRUE
			spawn()
				hear("<h1>Starting in 3</h1>")
				//sleep(10)
				hear("<h1> -- 2</h1>")
				//sleep(10)
				hear("<h1> -- 1</h1>")
				//sleep(10)
				hear("<h1>GO!</h1>")
				main()
			// Signal a successful start
			return TRUE

		main()
			// Give each mover in game a turn
			for(var/mover/mover in src)
				mover.behavior()
			// Move all movable atoms based on their velocity
				if(!(mover.velocity.x || mover.velocity.y)) continue
				var newX = mover.step_x + mover.velocity.x
				var newY = mover.step_y + mover.velocity.y
				if(!mover.Move(mover.loc, mover.dir, newX, newY))
					mover?.Move(mover.loc, mover.dir, newX, mover.step_y)
					mover?.Move(mover.loc, mover.dir, mover.step_x, newY)
			// Reduce velocity of all moving atoms based on friction
				var totalFriction = 0
				var totalTiles = 0
				if(!mover) continue
				for(var/tile/tLoc in mover.locs)
					totalFriction += tLoc.friction
					totalTiles ++
				if(totalTiles)
					var averageFriction = totalFriction / totalTiles
					mover.adjustVelocity(
						-min(averageFriction, abs(mover.velocity.x)) * sign(mover.velocity.x),
						-min(averageFriction, abs(mover.velocity.y)) * sign(mover.velocity.y)
					)
			// Grow Radishes
			if(rand(1,32) == 32)
				var /team/sproutColor = pick(teams)
				var /team/sproutTeam = teams[sproutColor]
				var /tile/farm/randomFarm = pick(sproutTeam.farms)
				randomFarm.sprout()
			// Count down the time
			time -= TICK_DELAY
			timer.refresh(time)
			// End the game if time is up
			if(time <= 0)
				end()
			// Otherwise call next recursion
			else
				spawn(TICK_DELAY)
					main()

		end()
			// Determine if one team has a higher score than all others
			var doubt = FALSE
			var /team/highScoreTeam
			for(var/teamColor in teams)
				var /team/scoreTeam = teams[teamColor]
				if(!highScoreTeam)
					highScoreTeam = scoreTeam
					continue
				if(scoreTeam.score > highScoreTeam.score)
					highScoreTeam = scoreTeam
					doubt = FALSE
					continue
				if(scoreTeam.score == highScoreTeam.score)
					doubt = TRUE
			// Handle situations with a clear winner
			if(!doubt)
				hear({"\
					<h2 style="color:[highScoreTeam.color]">\
					[uppertext(highScoreTeam.color)] has won with a score of [highScoreTeam.score]!\
					</h2>\
					"})
				showResults()
				system.delGame(gameId)
				return
			// Extend time when teams have scored the same points (overtime)
			if(!overtime)
				overtime = TRUE
				time = 150
				hear("<h2>Overtime!</h2>")
				spawn(1)
					main()
			// Declare a draw when teams have the same scores after overtime
			else
				hear("<h2>The Game is a Draw.</h2>")
				showResults()
				system.delGame(gameId)

		showResults()
			for(var/interface/player in contents)
				new /interface/results(player.client)


//-- HUD - Heads Up Display system for Time & Scores ---------------------------

game/hud
	parent_type = /datum
	sprite
		parent_type = /obj
		layer = 6
		pixel_y = -6
		icon = 'digits.dmi'
		digit
			layer = 7
			proc/refresh(which)
				icon_state = "[which]"

//-- Score Display - Shows teams' scores ---------
game/hud/score
	parent_type = /datum
	var
		list/digits = new(3)
		team
	New(game/newGame, teamColor)
		team = teamColor
		setup(newGame)
	proc
		setup(game/newGame)
			var teamPositions = list(TEAM_RED=6, TEAM_BLUE=13, TEAM_GREEN=3, TEAM_YELLOW=16)
			var teamPosition = teamPositions[team]
			//
			var /game/hud/sprite/background = new(locate(teamPosition, world.maxy, newGame.zPosition))
			background.layer--
			background.icon = 'digit_backgrounds.dmi'
			background.icon_state = "score"
			//
			for(var/digitIndex = 1 to digits.len)
				var /game/hud/sprite/digit/digit = new(locate(teamPosition+1, world.maxy, newGame.zPosition))
				digit.pixel_x = (digitIndex-1)*6 - 4
				digit.icon_state = " "
				digit.color = team
				digits[digitIndex] = digit
			//
			refresh(0)
		refresh(teamScore)
			for(var/digitIndex = 1 to digits.len)
				var /game/hud/sprite/digit/digit = digits[digitIndex]
				var factor = 100/(10**(digitIndex-1)) // 1 => 100, 2 => 10, 3 => 1
				var digitValue = round(teamScore/factor)
				if(!digitValue && digitIndex == 1) digitValue = null
				digit.refresh(digitValue)
				teamScore -= digitValue*factor

//-- Timer - On map countdown display ------------
game/hud/timer
	parent_type = /datum
	var
		digitColor = "#0c0"
		game/hud/sprite/digit/minute
		game/hud/sprite/digit/second_10
		game/hud/sprite/digit/second_1
	New(game/newGame)
		setup(newGame)
	proc
		setup(game/newGame)
			var /game/hud/sprite/background = new(locate(9, world.maxy, newGame.zPosition))
			background.layer--
			background.icon = 'digit_backgrounds.dmi'
			background.icon_state = "time"
			background.pixel_x = 3
			//
			minute    = new(locate(10, world.maxy, newGame.zPosition))
			second_10 = new(locate(11, world.maxy, newGame.zPosition))
			second_1  = new(locate(11, world.maxy, newGame.zPosition))
			minute.color    = digitColor
			second_10.color = digitColor
			second_1.color  = digitColor
			minute.pixel_x   = 4
			second_10.pixel_x = -2
			second_1.pixel_x = 4
			minute.icon_state    = "-"
			second_10.icon_state = "-"
			second_1.icon_state  = "-"
			//
			refresh(newGame.time)
		refresh(time)
			time = round(time)
			var/ticks   = time % 10
			time = (time - ticks) / 10
			var/seconds = time % 60
			time = (time - seconds) / 60
			var/minutes = time
			minute.refresh(minutes)
			second_10.refresh((seconds - (seconds%10))/10)
			second_1.refresh(seconds%10)
