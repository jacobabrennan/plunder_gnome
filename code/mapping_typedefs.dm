

//-- Mapping Type Definitions --------------------------------------------------


//-- Tiles ---------------------------------------------------------------------

tile
	parent_type = /turf
	icon = 'farm.dmi'
	density = FALSE
	var
		friction = 0.5
	lawn
		icon_state = TEAM_GREEN
	bush
		icon_state = "tree_green"
		density = TRUE // Density required for built in path finding
		movement = MOVEMENT_WALL
		layer = MOB_LAYER
	path
		icon_state = "flagstone"
	water
		icon_state = "water"
		density = TRUE // Density required for built in path finding
		movement = MOVEMENT_WATER
	snow
		icon_state = "snow"
		friction = 0
	farm
		icon_state = "farm"
		proc
			sprout()
				if(!(locate(/radish) in src))
					new /radish/farm(src)
					/* Nudge for more random look
					newGrowth.step_x += pick(-1, 0, 1)
					newGrowth.step_y += pick(-1, 0, 1)*/
	house
		icon = 'farm.dmi'
		icon_state = "siding"
		density = TRUE // Density required for built in path finding
		movement = MOVEMENT_WALL
		layer = MOB_LAYER

	houseOverhang
		parent_type = /obj
		icon = 'farm.dmi'
		icon_state = "roof_back_left"
		density = FALSE // Density required for built in path finding
		layer = MOB_LAYER + 1

	goal
		icon = 'farm.dmi'
		movement = MOVEMENT_WALL
		density = TRUE // Density required for built in path finding
		var
			team as text
		Bumped(var/atom/movable/bumper)
			// Cancel out if the bumper isn't a player
			var /character/transactionChar = bumper
			if(!istype(transactionChar)) return
			// Cancel out if the bumper is stunned
			if(transactionChar.stunned) return
			// Deliver Radishes if teams match
			var /game/game = game(src)
			if(team == transactionChar.team)
				if(!transactionChar.radishes)
					return
				game.adjustScore(team, transactionChar.radishes)
				transactionChar.adjustRadishes(-transactionChar.radishes)
			// Plunder Radishes if teams don't match
			else
				var /team/ownTeam = game.teams[team]
				if(!ownTeam.score) return
				if(transactionChar.plunderCoolDown) return
				var award = transactionChar.adjustRadishes(1)
				if(!award) return
				transactionChar.plunderCoolDown = DELAY_PLUNDER
				game.adjustScore(team, -award)


//-- Critters - AI controlled obstacles ----------------------------------------

critter
	parent_type = /mover
	icon_state = "1"
	Crossed(var/character/crossChar)
		. = ..()
		// Stun characters
		if(istype(crossChar))
			crossChar.stun(src, 0)
	onCross(var/character/crossChar)
		. = ..()
		// Stun characters
		if(istype(crossChar))
			crossChar.stun(src, 0)

	//-- Critter Type Defs ---------------------------

	mrbubble
		icon = 'mrbubble.dmi'
		accl = 3
		max_vel = 3
		stepAnimationDelay = 1
		behavior()
			// Move 1px randomly
			if(rand() < 3/4) return
			var direction = 0
			direction |= pick(NORTH, 0, SOUTH)
			direction |= pick(EAST, 0, WEST)
			go(direction)

	salty
		icon = 'salty.dmi'
		accl = 2
		Bump(var/atom/obstruction)
			. = ..()
			dir = pick((list(NORTH, SOUTH, EAST, WEST) - dir))
		behavior()
			// Move in straight lines, sometimes changing direction
			if(rand()*16 > 14)
				dir = pick(NORTH, SOUTH, EAST, WEST)
			go(dir)

	ruttle
		icon = 'ruttle.dmi'
		accl = 1
		max_vel = 1
		var
			buzzTime = 0
			critter/ruttle/case/case
		New()
			.=..()
			case = new(src.contents)
		Bump(var/atom/obstruction)
			. = ..()
			if(!buzzTime)
				dir = pick((list(NORTH, SOUTH, EAST, WEST) - dir))
		behavior()
			// Move in straight lines. Randomly stops to "buzz".
			// If we are buzzing, buzz and do nothing else.
			if(buzzTime)
				buzzTime--
				buzz()
				return
			// If we've just finished buzzing, clean up.
			if(icon_state == "buzzing")
				icon_state = "1"
				case.loc = contents
			// Sometimes change direction
			if(rand()*32 > 31)
				dir = pick(NORTH, SOUTH, EAST, WEST)
			// Sometimes stop to buzz
			if(rand()*64 > 63)
				buzzTime = rand(16,32)
				case.centerLoc(src)
			// Move in current direction
			go(dir)
		proc
			buzz()
				icon_state = "buzzing"
				case.centerLoc(src)
				step(case, pick(NORTH,SOUTH,EAST,WEST), TILE_SIZE/2)
				case.dir = dir
				for(var/character/hitTarget in bounds(case))
					Bump(hitTarget)
		case
			parent_type = /obj
			icon = 'ruttle.dmi'
			icon_state = "case"
			layer = FLY_LAYER


//-- Placement Markers - Determines where players are placed on map ------------

placementMarker
	parent_type = /obj
	icon = 'markers.dmi'
	var
		team = TEAM_RED
		position = 1
	position_red_1
		icon_state = "red_1"
		team = TEAM_RED
		position = 1
	position_red_2
		icon_state = "red_2"
		team = TEAM_RED
		position = 2
	position_red_3
		icon_state = "red_3"
		team = TEAM_RED
		position = 3
	position_blue_1
		icon_state = "blue_1"
		team = TEAM_BLUE
		position = 1
	position_blue_2
		icon_state = "blue_2"
		team = TEAM_BLUE
		position = 2
	position_blue_3
		icon_state = "blue_3"
		team = TEAM_BLUE
		position = 3