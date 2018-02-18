

//-- Intelligence - Controller for AI characters -------------------------------

intelligence
	parent_type = /mob
	proc
		control(character/controlChar)

interface
	parent_type = /intelligence

character/rival
	parent_type = /intelligence
	var
		character/character
		team
	New(character/newChar)
		. = ..()
		newChar.player = src
		character = newChar
		team = character.team
	control(character/controlChar)
		var commands = call(src, dominantGoal)()
		return commands


//-- Goals ---------------------------------------
character/rival

	proc/trackPath(atom/target)
		// Determine next step along path
		if(!path || !path.len)
			return 0
		var /turf/nextStep = path[1]
		if(nextStep in character.locs)// == nextStep && character.locs.len == 1)
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
			//diag(newGoal)
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
			// If still no target, pick one of own team's farms
			if(!target)
				var /game/ownGame = game(character)
				var /team/ownTeam = ownGame.teams[team]
				target = pick(ownTeam.farms)
				path = null
			// If no Path, get path
			if(!path && target && !(target in locs))
				getPath(target)
			// Find direction to target
			ASSERT(target)
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
