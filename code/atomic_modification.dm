

//-- Redefine Atomic System ----------------------------------------------------


//-- Default World Configuration -----------------
client/perspective = EYE_PERSPECTIVE
world
	tick_lag = TICK_DELAY
	map_format = TOPDOWN_MAP
	icon_size = TILE_SIZE


//-- Access Utilities ----------------------------
proc/aloc(atom/contained)
	if(!istype(contained)) return null
	var/turf/locTurf = locate(contained.x, contained.y, contained.z)
	if(!locTurf) return null
	return locTurf.loc
proc/game(reference)
	// Try to locate game from atom map position
	var /game/G = aloc(reference)
	if(istype(G)) return G
	// Try to locate game from gameId variable
	var /datum/D = reference
	if(istype(D) && "gameId" in D.vars)
		G = system.getGame(D.vars["gameId"])
		if(istype(G)) return G
	// Return failure
	return null


//-- Movement & Density --------------------------
atom/movable/step_size = 1 // Necessary for all objects to use pixel movement
atom/proc/Bumped(var/atom/movable/bumper)
atom/movable/Bump(var/atom/Obstruction)
	Obstruction.Bumped(src)
	. = ..()
turf
	var/movement = MOVEMENT_NONE
	Enter(mover/entrant)
		if(!istype(entrant)) return ..()
		if(!(entrant.movement & movement))
			entrant.Bump(src)
			return FALSE
		. = ..()
mob/density = FALSE
tile/movement = MOVEMENT_FLOOR
tile/density = FALSE
mover
	var/movement = MOVEMENT_ALL
atom/movable
	Cross()
		return TRUE
	Crossed(atom/movable/crosser)
		. = ..()
		crosser.onCross(src)
	proc/onCross(atom/movable/crosser)
atom/movable
	proc/centerLoc(var/atom/movable/_center)
		if(istype(_center))
			forceLoc(_center.loc)
			step_x = _center.step_x + (_center.bound_x) + (_center.bound_width -bound_width )/2
			step_y = _center.step_y + (_center.bound_y) + (_center.bound_height-bound_height)/2
		else
			forceLoc(locate(_center.x, _center.y, _center.z))
			step_x = (TILE_SIZE-bound_width )/2
			step_y = (TILE_SIZE-bound_height)/2
	proc/forceLoc(atom/newLoc)
		var/success = Move(newLoc)
		if(success) return TRUE
		// Handle case where oldLoc.Exit was preventing movement
		var/area/oldLoc = loc
		var/successLeave = Move(null)
		loc = null
		// Handle the case where newLoc.Enter is preventing movement
		success = Move(newLoc)
		loc = newLoc
		if(!successLeave && oldLoc)
			oldLoc.Exited(src, newLoc)
			if(!istype(oldLoc))
				oldLoc = aloc(oldLoc)
				if(istype(oldLoc))
					oldLoc.Exited(src, newLoc)
		if(!success && newLoc)
			newLoc.Entered(src, oldLoc)
		return TRUE
	Del()
		forceLoc(null)
		. = ..()


//-- Position, Direction, & Distance -------------

atom/movable/proc/directionTo(atom/movable/target)
	// Determine the closest cardinal direction from src to target
	var deltaX
	var deltaY
	if(istype(target))
		deltaX = (target.x*TILE_SIZE+target.step_x+target.bound_width /2) - (x*TILE_SIZE+step_x+bound_width /2)
		deltaY = (target.y*TILE_SIZE+target.step_y+target.bound_height/2) - (y*TILE_SIZE+step_y+bound_height/2)
	else
		deltaX = ((target.x+1/2)*TILE_SIZE) - (x*TILE_SIZE+step_x+bound_width /2)
		deltaY = ((target.y+1/2)*TILE_SIZE) - (y*TILE_SIZE+step_y+bound_height/2)
	var direction = 0
	if(deltaY > 0) direction |= NORTH
	if(deltaY < 0) direction |= SOUTH
	if(deltaX > 0) direction |= EAST
	if(deltaX < 0) direction |= WEST
	return direction

atom/movable/proc/cardinalTo(atom/movable/target)
	// Determine the closest cardinal direction from src to target
	var/deltaX = (target.x*TILE_SIZE+target.step_x+target.bound_width /2) - (x*TILE_SIZE+step_x+bound_width /2)
	var/deltaY = (target.y*TILE_SIZE+target.step_y+target.bound_height/2) - (y*TILE_SIZE+step_y+bound_height/2)
	if(abs(deltaX) >= abs(deltaY))
		if(deltaX >= 0) return EAST
		else return WEST
	else
		if(deltaY >= 0) return NORTH
		else return SOUTH

atom/proc/closest(targetType, distance)
	// Find the closest instance of targetType within distance of src
	var /list/closeList = obounds(src, distance)
	var /atom/closeTarget
	var closeDist = 99999
	var /atom/testTarget
	do
		testTarget = locate(targetType) in closeList
		if(!testTarget)
			break
		closeList.Remove(testTarget)
		var testDist = bounds_dist(src, testTarget)
		if(testDist < closeDist)
			closeDist = testDist
			closeTarget = testTarget
	while(testTarget)
	return closeTarget
