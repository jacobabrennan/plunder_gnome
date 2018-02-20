

//-- Title Screen --------------------------------------------------------------

interface/titleScreen
	var
		interface/titleScreen/join/joinButton
		joining
	Login()
		.=..()
		loc = locate(1,1,1)
		joinButton = new()
		client.screen.Add(joinButton)
	proc
		spectate()
			var /game/game = pick(system.games)
			game.addSpectator(client)
		join()
			if(joining) return
			joining = TRUE
			sleep(3)
			del joinButton
			system.titleScreen.removePlayer(src)
			system.nextGame.addPlayer(client)
	join
		parent_type = /button
		displayName = "join"
		screen_loc = "4:8,4:8"
		Click()
			. = ..()
			var /interface/titleScreen/title = usr
			if(istype(title))
				title.join()


//--

titleScreen
	var
		active = FALSE
		list/players = new()
	proc
		addPlayer(newClient)
			players.Add(new /interface/titleScreen(newClient))
			activate()

		removePlayer(interface/titleScreen/oldPlayer)
			players.Remove(oldPlayer)
			if(!players.len)
				active = FALSE

		activate()
			if(active) return
			active = TRUE
			spawn()
				main()
		main()
			if(!players.len) active = FALSE
			if(!active) return
			farmer.behavior(src)
			if(radishes.len < 5 && rand() < 1/32)
				var /tile/farm/sproutFarm = pick(farms)
				var /radish/sprout = sproutFarm.sprout()
				if(sprout)
					radishes.Add(sprout)
			spawn(TICK_DELAY)
				main()
	//-- Farm
	var
		titleScreen/farmer/farmer
		tile/goal
		list/farms = list()
		list/radishes = list()

	New()
		. = ..()
		//
		new /titleScreen/title(locate(2, 8, 1))
		//
		farmer = new(locate(16, 7, 1))
		goal = locate(16, 8, 1)
		// Find Farms
		for(var/tile/farm/ownFarm in orange(farmer, 6))
			farms.Add(ownFarm)
		// Color Houses
		for(var/tile/house/housePart in orange(farmer, 4))
			housePart.color = list("#fa5", "#fa5", "#c00")
		for(var/tile/houseOverhang/housePart in orange(farmer, 4))
			housePart.color = list("#fa5", "#fa5", "#c00")
		// Sprout Radishes
		while(radishes.len < 5)
			var /tile/farm/F = pick(farms)
			var /radish/newRadish = locate() in F
			if(!newRadish)
				newRadish = F.sprout()
				if(newRadish)
					radishes.Add(newRadish)
			sleep(1)

	title
		parent_type = /obj
		icon = 'title.png'
		layer = FLY_LAYER
		pixel_y = 4

	farmer
		parent_type = /character
		icon = 'base_gnome.dmi'
		bound_height = 14
		bound_width  = 12
		bound_x = 2
		capacity = 5
		strength = 4
		accl = 1
		max_vel = 2
		var
			atom/target

		New()
			. = ..()
			// Color Icon
			var /icon/I = icon(icon)
			var newColorBrightness = 255
			var newColor = rgb(newColorBrightness, 0, 0)
			I.SwapColor(rgb(255,0,255), newColor)
			icon = I

		behavior(titleScreen/titleScreen)
			// Try to locate radish to Target
			if(radishes >= capacity)
				target = titleScreen.goal
			else if(!target)
				if(titleScreen.radishes.len && radishes < capacity)
					target = pick(titleScreen.radishes)
					titleScreen.radishes.Remove(target)
			// Target Goal
				else if(radishes)
					target = titleScreen.goal
			// Move
			if(target)
				if(target in obounds(src))
					target = null
				else
					go(directionTo(target))
			else
				dir = WEST
			if(velocity.x || velocity.y)
				var newX = step_x + velocity.x
				var newY = step_y + velocity.y
				if(!Move(loc, dir, newX, newY))
					Move(loc, dir, newX, step_y)
					Move(loc, dir, step_x, newY)
			var velMag = velocity.x
			if(velMag)
				velocity.x -= sign(velMag)*min(1, abs(velMag))
			velMag = velocity.y
			if(velMag) velocity.y -= sign(velMag)*min(1, abs(velMag))
			//

		Bump(obstruction)
			if(!istype(obstruction, /tile/house)) return
			// Deliver Radishes
			if(!radishes) return
			adjustRadishes(-radishes)
			target = null


//-- Character Type Definitions ------------------------------------------------
