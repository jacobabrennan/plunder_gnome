

//-- Intelligence - Controller for AI characters -------------------------------

intelligence
	parent_type = /mob
	proc
		attachCharacter()
		control(character/controlChar)
		bounce(bouncer, bounceDir)

interface
	parent_type = /intelligence

character/rival
	parent_type = /intelligence
	var
		character/character
		team
	New(character/newChar)
		. = ..()
		attachCharacter(newChar)
	Del()
		// it's a mystery
	attachCharacter(character/newChar)
		newChar.player = src
		character = newChar
		team = character.team
		reactionQueue = new(character.reactionTime)
	control(character/controlChar)
		var commands = danger()
		if(commands)
			switchGoal("farm")
		else
			commands = call(src, dominantGoal)()
		return commands


//-- Goals ---------------------------------------
character/rival

	proc/trackPath(atom/target)
		// Determine next step along path
		if(!path || !path.len)
			return 0
		var /turf/nextStep = path[1]
		if(nextStep in character.locs)
			path.Cut(1,2)
			if(path.len)
				nextStep = path[1]
			else
				path = null
				target = null
		// Compile commands (directions)
		var commands = character.directionTo(nextStep)
		return commands

	proc/centerOffset(var/atom/movable/target)
		var deltaX
		var deltaY
		if(istype(target))
			deltaX = (target.x*TILE_SIZE+target.step_x+target.bound_width /2) - (character.x*TILE_SIZE+character.step_x+character.bound_width /2)
			deltaY = (target.y*TILE_SIZE+target.step_y+target.bound_height/2) - (character.y*TILE_SIZE+character.step_y+character.bound_height/2)
		else
			deltaX = ((target.x+1/2)*TILE_SIZE) - (character.x*TILE_SIZE+character.step_x+character.bound_width /2)
			deltaY = ((target.y+1/2)*TILE_SIZE) - (character.y*TILE_SIZE+character.step_y+character.bound_height/2)
		return max(deltaX, deltaY)


character/rival
	var
		dominantGoal = "farm"
		atom/target
		list/path
		list/pathStorage
	proc

		switchGoal(newGoal)
			//for(var/tile/T in pathStorage)
			//	T.color = null
			target = null
			path = null
			dominantGoal = newGoal
			//character.loc.color = "blue"

		getPath(target)
			//for(var/tile/T in pathStorage)
			//	T.color = null
			var /path/pather = new(null, null, target)
			path = pather.aStar(character.loc, target)
			pathStorage = path.Copy()
			//for(var/tile/T in path)
			//	T.color = "green"

		farm()
			// Change goal if we have enough radishes
			if(character.radishes >= character.capacity)
				switchGoal("deliver")
				return
			// Target a radish within 5 squares (the largest farm size)
			var /radish/radishTarget = target
			if(!istype(radishTarget))
				var searchDist = 10 - character.radishes*2
				radishTarget = character.closest(/radish, searchDist*TILE_SIZE)
				if(radishTarget)
					target = radishTarget
					path = null
			// If no target, and we have radishes, deliver them
			if(!target && character.radishes)
				switchGoal("deliver")
				return
			// If still no target, see if we have radishes on the farm
			if(!target)
				var /game/ownGame = game(character)
				var /team/ownTeam = ownGame.teams[team]
				var /tile/farm/ownFarm = pick(ownTeam.farms)
				if(locate(/radish) in obounds(ownFarm, TILE_SIZE*2))
					switchGoal("farm")
					return
			// Otherwise, go raiding
				else
					switchGoal("plunder")
					return
			// If no Path, get path
			if(!path && target && !(target in locs))
				getPath(target)
				if(!path) return
			// Find direction to target
			return trackPath(target)

		deliver()
			// If we don't have radishes, go find some
			if(!character.radishes)
				switchGoal("farm")
				return
			// Find target if we don't already have it
			if(!istype(target, /tile/goal) || !path)
				var /game/ownGame = game(character)
				var /team/ownTeam = ownGame.teams[team]
				target = ownTeam.goal
				getPath(target)
			// Find direction to target
			return trackPath(target)

		plunder()
			var /game/ownGame = game(character)
			var /team/opponentTeam
			// Get the opposite team's goal
			if(!target)
				var /team/ownTeam = ownGame.teams[team]
				var /list/teamsCopy = ownGame.teams.Copy()
				teamsCopy.Remove(ownTeam.color)
				while(teamsCopy.len)
					var teamColor = pick(teamsCopy)
					teamsCopy.Remove(teamColor)
					var /team/testTeam = ownGame.teams[teamColor]
					if(!opponentTeam || testTeam.score > opponentTeam.score)
						opponentTeam = testTeam
				if(!opponentTeam)
					switchGoal("farm")
					return
				target = opponentTeam.goal
				getPath(target)
			//
			var /tile/goal/goalTarget = target
			opponentTeam = ownGame.teams[goalTarget.team]
			if(character.radishes == character.capacity || !opponentTeam.score)
				switchGoal("deliver")
			return trackPath(target)

	var
		list/reactionQueue
	bounce()
		reactionQueue[1] = pick(NORTH, SOUTH, EAST, WEST)
		. = ..()
	proc
		danger()
			// Find the closest hostile target
			var /list/closeList = obounds(character, TILE_SIZE*2)
			var /character/closeTarget
			var closeDist = 99999
			var /character/testTarget
			do
				testTarget = locate(/character) in closeList
				if(!testTarget)
					break
				closeList.Remove(testTarget)
				// Determine if target is hostile, can reach us, or we can reach it
				if(testTarget.team == character.team) continue
				if(testTarget.stunned || testTarget.invulnerable) continue
				var closing = ((testTarget.dir&testTarget.directionTo(character)) && testTarget.max_vel > character.max_vel)
				var radishes = (testTarget.radishes > character.radishes && character.max_vel > testTarget.max_vel)
				if(!closing && !radishes) continue
				//
				var testDist = bounds_dist(character, testTarget)
				if(testDist < closeDist)
					closeDist = testDist
					closeTarget = testTarget
			while(testTarget)
			// Determine danger command
			var commands = 0
			if(closeTarget)
				commands = character.directionTo(closeTarget)
			// Manage danger queue
			reactionQueue.Add(commands)
			commands = reactionQueue[1]
			reactionQueue.Cut(1,2)
			return commands



#ifdef SomeAINotes
Farm
	low intensity
	Pro
		Default
		When our farm has lots of radishes
	Con
		When they're in our farm
	Algorithm
		Go to farm
		collect radishes
		Switch to Deliver
Raid
	low intensity
	Pro
		When their farm has lots of radishes
	Con
		When they're in their farm
	Algorithm
		Go to their farm
		collect radishes
		Switch to Deliver
Deliver
	low intensity
	Pro
		We have lots of radishes
	Algorithm
		Go to our Goal
Plunder
	low intensity
	Pro
		Their goal is unguarded
		They have more radishes than us
	Con
		We're far away
	Algorithm
		Go to their Goal
Defend
	high intensity
	Pro
		There are no radishes to farm
		They're closer to the goal
		We have more radishes
	Algorithm

Disrupt
	high intensity
	Pro
		They're close
		They have lots of radishes

Pursue Radish
Face Down Intruder
Push out Intruder
Deliver

#endif
