

//-- Radishes! -----------------------------------------------------------------

radish
	parent_type = /mover
	icon = 'farm.dmi'
	icon_state = "radish"
	bound_width  = 6
	bound_height = 6
	movement = MOVEMENT_FLOOR
	Crossed(character/crosser)
		. = ..()
		if(istype(crosser))
			get(crosser)
	onCross(character/obstruction)
		. = ..()
		if(istype(obstruction))
			get(obstruction)
	proc
		get(character/getChar)
			// Cancel out if getChar is stunned or can't carry any more
			if(getChar.stunned) return
			if(getChar.radishes >= getChar.capacity) return
			// Play animation
			new /radish/animation(src)
			// Adjust getChar radishes and delete self
			getChar.adjustRadishes(1)
			del src

	animation
		parent_type = /obj
		layer = MOB_LAYER+1
		var
			animateTime = 3
		New(radish/model)
			// Clone oldRadish (some things aren't covered by /appearance)
			bound_width  = model.bound_width
			bound_height = model.bound_height
			centerLoc(model)
			appearance = model.appearance
			dir = model.dir
			// Animate a lift into the air and fade
			animate(src, pixel_y=TILE_SIZE, alpha=0, time=animateTime)
			spawn(animateTime)
				del src

	farm
		icon_state = "radish"
		pixel_x = -1
		New(newLoc)
			. = ..()
			// Center on Farm
			if(newLoc)
				centerLoc(newLoc)
			// Prep randomized graphic
			icon_state = "empty"
			dir = pick(NORTH, SOUTH, EAST, WEST)
			// Show the grow animation
			spawn(1)
				flick("radish_sprout", src)
				icon_state = initial(icon_state)
			// Have any character on top get the radish
				sleep(5)
				var /character/overGetter = locate() in obounds(src)
				if(overGetter)
					get(overGetter)
					return
			// Randomly Bob now and then
				while(src)
					sleep(rand(80,150))
					pixel_y -= 1
					sleep(2)
					pixel_y += 1

	spilled
		icon_state = "radish_spill"
		pixel_x = -2
		pixel_y = -2
		New()
			.=..()
			dir = pick(NORTH,NORTHEAST,WEST,SOUTHEAST,SOUTH,NORTHWEST,EAST,SOUTHWEST)


//-- Radish Meters - Displays the radishes a character is carrying -------------

system
	var
		list/radishMeters3 = new(4)
		list/radishMeters5 = new(6)
		list/radishMeters8 = new(9)
	New()
		. = ..()
		// Prepare radish meter overlays
		var /list/meterLists = list(radishMeters3, radishMeters5, radishMeters8)
		var /obj/temp
		for(var/list/meter in meterLists)
			for(var/I = 1 to meter.len)
				temp = new()
				var /image/protoAppearance = image('radish_meter.dmi', null, "radish_[I-1]/[meter.len-1]", FLY_LAYER)
				protoAppearance.pixel_y = TILE_SIZE+2
				temp.overlays.Add(protoAppearance)
				for(var/appearance in temp.overlays)
					meter[I] = appearance
				del temp

character
	var
		mutable_appearance/radishMeter
	New()
		. = ..()
		adjustRadishes()
	proc
		adjustRadishes(amount)
			// Cancel out if this character doesn't collect radishes
			if(!capacity) return
			// Bound amount so radishes doesn't go over capacity or below zero
			var untilFull = capacity - radishes
			amount = min(amount, untilFull)
			amount = max(amount, -radishes)
			// Adjust the amount of radishes carried
			var oldRadishCount = radishes
			radishes += amount
			// Refresh the carried radishes display
			overlays.Remove(radishMeter)
			switch(capacity)
				if(3) radishMeter = system.radishMeters3[radishes+1]
				if(5) radishMeter = system.radishMeters5[radishes+1]
				if(8) radishMeter = system.radishMeters8[radishes+1]
			overlays.Add(radishMeter)
			// Return the actual adjustment quantity
			return radishes - oldRadishCount
