

//-- Movement & Key State ------------------------------------------------------

//-- Movers --------------------------------------
mover
	parent_type = /mob
	movement = MOVEMENT_FLOOR
	var
		accl = 1
		max_vel = 2
		// Nonconfigurable:
		coord/velocity = new(0,0)
		steps = 0
		stepAnimationDelay = 3
	proc
		behavior()
			//
		adjustVelocity(deltaX, deltaY)
			velocity.x += deltaX
			velocity.y += deltaY
			if(abs(velocity.x) > MAX_VELOCITY)
				velocity.x = MAX_VELOCITY * sign(velocity.x)
			if(abs(velocity.y) > MAX_VELOCITY)
				velocity.y = MAX_VELOCITY * sign(velocity.y)
		go(direction)
			// Change run animation frame
			if(direction)
				steps++
			if(direction && !(steps%stepAnimationDelay))
				switch(copytext(icon_state,1,2))
					if("0") icon_state = "1"
					if("1") icon_state = "2"
					if("2") icon_state = "3"
					if("3") icon_state = "0"
			// Adjust velocity and direction
			var acclX = 0
			var acclY = 0
			var newDir = 0
			if(direction & NORTH)
				newDir |= NORTH
				if(velocity.y < max_vel)
					acclY += accl
			else if(direction & SOUTH)
				newDir |= SOUTH
				if(velocity.y > -max_vel)
					acclY -= accl
			if(direction & EAST)
				newDir |= EAST
				if(velocity.x < max_vel)
					acclX += accl
			else if(direction & WEST)
				newDir |= WEST
				if(velocity.x > -max_vel)
					acclX -= accl
			adjustVelocity(acclX, acclY)
			dir = newDir


//-- Key State Control (with Kaiochao.AnyMacro) --------------------------------

client/New()
	. = ..()
	macros.client = src

interface/proc
	commandDown()
	commandUp()

button_tracker
	var/client/client
	var/list/preferences = list(
		North=NORTH, Numpad8=NORTH, W=NORTH,
		South=SOUTH, Numpad2=SOUTH, S=SOUTH,
		East = EAST, Numpad6= EAST, D= EAST,
		West = WEST, Numpad4= WEST, A= WEST,
		Space=PRIMARY,
		//Z=SECONDARY, X=TERTIARY, C=QUATERNARY,
		//Tab  = BACK
	)
	var/commands = 0

	// When a button is pressed, send a message to the output target.
	Pressed(button)
		var command = preferences[button]
		if(!command) return
		commands |= command
		client.interface.commandDown(command)

	// When a button is released, send a message to the output target.
	Released(button)
		var command = preferences[button]
		if(!command) return
		commands &= ~command
		client.interface.commandUp(command)
	proc/checkCommand(command)
		return commands&command