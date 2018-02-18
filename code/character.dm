

//-- Character - Players Characters & AI Critters ------------------------------

character
	parent_type = /mover
	icon_state = "1"
	movement = MOVEMENT_FLOOR
	var
		strength = 1
		capacity = CARRY_MAX
		// Nonconfigurable:
		intelligence/player
		team
		radishes = 0
		stunned = FALSE
		invulnerable = FALSE
		plunderCoolDown = 0
	behavior()
		if(plunderCoolDown) plunderCoolDown--
		if(player)
			var commands = player.control(src)
			var direction = (NORTH|SOUTH|EAST|WEST) & commands
			go(direction)


	//-- Team Setup ----------------------------------
	proc
		setTeam(newTeam, position)
			// Set Team
			team = newTeam
			// Color Icon
			var /icon/I = icon(icon)
			var newColorBrightness
			var newColor
			switch(position)
				if(1) newColorBrightness = 255
				if(2) newColorBrightness = 119
				if(3) newColorBrightness = 187
			switch(team)
				if(TEAM_RED   ) newColor = rgb(newColorBrightness, 0, 0)
				if(TEAM_BLUE  ) newColor = rgb(0, 0, newColorBrightness)
				if(TEAM_GREEN ) newColor = rgb(0, newColorBrightness, 0)
				if(TEAM_YELLOW) newColor = rgb(newColorBrightness, newColorBrightness, 0)
			I.SwapColor(rgb(255,0,255), newColor)
			icon = I

	//-- Movement Animation --------------------------
	go(var/direction as num)
		// If the character is stunned, do nothing
		if(stunned) return
		//
		var oldState = icon_state
		. = ..()
		if(invulnerable && icon_state != oldState)
			icon_state += "_flash"

	//-- Player Stunning -----------------------------
	proc
		stun(var/character/C, var/bump_dir)
			// Cancel out if character is already stunned or invulnerable
			if(stunned || invulnerable) return
			// Accelerate character away from bumper
			if(bump_dir)
				switch(bump_dir)
					if(NORTH) velocity.y += 4
					if(SOUTH) velocity.y -= 4
					if(EAST ) velocity.x += 4
					if(WEST ) velocity.x -= 4
			// Show stunned graphic
			stunned = TRUE
			icon_state = "stunned"
			// Spill all collected Radishes
			for(var/I = 1 to radishes)
				var /radish/spilled/r = new(loc)
				r.centerLoc(src)
				var spillSpeed = TILE_SIZE*(3/8)
				r.velocity = coord(
					rand(0,spillSpeed) * pick(-1,1),
					rand(0,spillSpeed) * pick(-1,1)
				)
			adjustRadishes(-radishes)
			// After a delay, un-stun character and make invulnerable
			spawn(TIME_STUN)
				if(stunned)
					stunned = FALSE
					invulnerable = TRUE
					icon_state = "1_flash"
					for(var/radish/boundedRadish in obounds(src))
						boundedRadish.get(src)
			// After a delay, remove invulnerability
					spawn(TIME_INVULNERABLE)
						if(invulnerable)
							icon_state = "1"
							invulnerable = FALSE

		bounce(character/bouncer, bounceDir)
			switch(bounceDir)
				if(NORTH) velocity.y += 6
				if(SOUTH) velocity.y -= 6
				if(EAST ) velocity.x += 6
				if(WEST ) velocity.x -= 6


	Cross(var/character/crosser)
		. = ..()
		// Cancel out if crosser isn't a character, is from the same team,
		// or is invulnerable.
		if(!istype(crosser)) return
		if(crosser.team == team) return
		if(invulnerable) return
		// Determine cross direction
		var stunDir = crosser.cardinalTo(src)
		// Stun src if crosser is crossing from back or sides
		if(!stunned && !(stunDir & turn(dir, 180)))// && (turn(stunDir, 180) != crosser.dir))
			stun(crosser, stunDir)
		// Bounce off each other
		. = FALSE
		var pushStrength = crosser.strength
		if(!stunned)
			if(pushStrength == strength)
				bounce(crosser, stunDir)
				crosser.bounce(src, turn(stunDir, 180))
			else if(pushStrength > strength)
				bounce(crosser, stunDir)
			else
				crosser.bounce(src, turn(stunDir, 180))
			return
		switch(stunDir)
			if(NORTH) adjustVelocity(0,  pushStrength)
			if(SOUTH) adjustVelocity(0, -pushStrength)
			if(EAST ) adjustVelocity( pushStrength, 0)
			if(WEST ) adjustVelocity(-pushStrength, 0)


//-- Character Type Definitions ------------------------------------------------
character
	//var
		//strength = 1
	george // Basic Gnome
		icon = 'base_gnome.dmi'
		bound_height = 14
		bound_width  = 12
		bound_x = 2
		capacity = 5
		strength = 4
		accl = 1
		max_vel = 2
	mathew // Basic Gnome
		icon = 'fat_gnome.dmi'
		bound_height = 16
		bound_width  = 16
		capacity = 8
		strength = 6
		accl = 1
		max_vel = 1
