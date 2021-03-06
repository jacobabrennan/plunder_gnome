

//-- Interface - Persistent connection between users and clients ----------

client
	var/interface/interface
	Del()
		// Necessary because client/key info not available in Logout
		if(interface)
			interface.disconnect(src)
		. = ..()

interface
	//- Connection -----------------------------------
	var
		switching
	New(client/_client)
		// don't do the default action: place interface inside of first argument
		if(_client)
			if(_client.interface) _client.interface.switching = TRUE
			client = _client
	Login()
		// don't do the default action: place interface at locate(1,1,1)
		if(client.interface)
			client.interface.disconnect(client)
		client.interface = src
	proc/disconnect(client/oldClient)
		// Necessary because client/key info not available in Logout
		// Called when:
		//	A client is deleted while still having an interface (player left server)
		//	A client logs into another interface while still owning this one (should never happen)

	//-- Invuluntary Disconnect Handling -------------
	var/interface/lagoutTimer/lagoutTimer
	Logout()
		del src

	//-- Chat Channel Handling -----------------------
	var
		showGameChat = FALSE
	Login()
		. = ..()
		if(showGameChat)
			winset(client, null, "chatChannels.tabs=channelSystem,channelGame; chatChannels.current-tab=channelGame;")
		else
			client << output(null, "outputChannelGame")
			winset(client, null, "chatChannels.tabs=channelSystem")


//-- Interface Type Definitions -------------------------------------------

//-- Holding - Contain player while preparing ----
interface/holding

//-- Clay - Players that have just connected -----
world/mob = /interface/clay
interface/clay
	New()
		. = ..()
		spawn() // Spawn necessary for reboots
			system.registerPlayer(client)

//-- Spectator - Watches Gameplay ----------------
interface/spectator
	//showGameChat = TRUE
	New(client/newClient, game/newGame)
		. = ..()
		loc = locate(newGame.x, newGame.y, newGame.z)


//-- Round Setup ----------------------------------------------------------

interface/characterSelect
	//showGameChat = TRUE
	var
		game/game
		character/character
	New(client/newClient, game/newGame)
		game = newGame
		loc = locate(game.x, game.y, game.z)
		. = ..()
	attachCharacter(character/newCharacter)
		// Change out buttons
		if(!character)
			for(var/button/cpuButton in cpu)
				client.screen.Add(cpuButton)
			for(var/interface/characterSelect/button/toggle/toggleButton in toggle)
				if(toggleButton.team == newCharacter.team)
					toggleButton.displayName = "minus"
					toggleButton.icon_state = "[toggleButton.team]_[toggleButton.displayName]"
				else
					client.screen.Remove(toggleButton)
			buttonLeave.screen_loc = "11:-4, 6:8"
			client.screen.Add(buttonStart)
		// Attach new character
		character = newCharacter
		character.player = src
		character.name = html_encode(key)
		// Apply Marker
		spawn(1)
			var /image/marker = image('player_marker.dmi', character, "marker", OBJ_LAYER)
			marker.pixel_x = -4
			marker.pixel_y = -5
			marker.alpha = 128
			client << marker
	proc
		detachCharacter()
			if(!character) return
			client.screen.Remove(buttonStart)
			buttonLeave.screen_loc = initial(screen_loc)
			for(var/button/cpuButton in cpu)
				client.screen.Remove(cpuButton)
			for(var/interface/characterSelect/button/toggle/toggleButton in toggle)
				if(toggleButton.team == character.team)
					toggleButton.displayName = "add"
					toggleButton.icon_state = "[toggleButton.team]_[toggleButton.displayName]"
				else
					client.screen.Add(toggleButton)
			game.removeCharacter(src)


	//-- Buttons -------------------------------------
	var
		interface/characterSelect/button/start/buttonStart
		interface/characterSelect/button/leave/buttonLeave
		list/toggle = new()
		list/cpu = new()
	verb
		StartGame()
			set name = "Start"
			for(var/button/cutButton in cpu+toggle)
				client.screen.Remove(cutButton)
			client.screen.Remove(buttonStart, buttonLeave)
			system.startGame()
		leave()
			game.removePlayer(src)
			system.titleScreen.addPlayer(client)
			del src

	Login()
		. = ..()
		buttonStart = new()
		buttonLeave = new()
		client.screen.Add(buttonLeave)
		for(var/teamColor in game.teams)
			var /placementMarker/teamPlacement = game.placements["[teamColor]_cpu"]
			if(!teamPlacement) continue
			//
			var /interface/characterSelect/button/cpu/teamCPU = new()
			teamCPU.team = teamColor
			switch(teamColor)
				if(TEAM_RED   ) teamCPU.color = list("#f00", "#fff", "#000")
				if(TEAM_BLUE  ) teamCPU.color = list("#33f", "#fff", "#000")
				if(TEAM_GREEN ) teamCPU.color = list("#6f0", "#fff", "#000")
				if(TEAM_YELLOW) teamCPU.color = list("#fc0", "#fff", "#000")
			var offset = (teamPlacement.x > world.maxx/2)? -3 : 1
			teamCPU.screen_loc = "[teamPlacement.x+offset], [teamPlacement.y]"
			cpu.Add(teamCPU)
			//
			var /interface/characterSelect/button/toggle/teamToggle = new()
			teamToggle.team = teamColor
			switch(teamColor)
				if(TEAM_RED   ) teamToggle.color = list("#f00", "#fff", "#000")
				if(TEAM_BLUE  ) teamToggle.color = list("#33f", "#fff", "#000")
				if(TEAM_GREEN ) teamToggle.color = list("#6f0", "#fff", "#000")
				if(TEAM_YELLOW) teamToggle.color = list("#fc0", "#fff", "#000")
			teamToggle.screen_loc = "[teamPlacement.x-1], [teamPlacement.y]"
			toggle.Add(teamToggle)
			//
			client.screen.Add(teamToggle)

	Logout()
		del buttonStart
		del buttonLeave
		for(var/button/loopButton in cpu+toggle)
			del loopButton
		if(!switching)
			leave()
		. = ..()

	button
		parent_type = /button
		start
			displayName = "start"
			screen_loc = "6:4, 6:8"
			Click()
				. = ..()
				var /interface/characterSelect/gameInt = usr
				if(!istype(gameInt)) return
				sleep(1)
				gameInt.StartGame()
		leave
			displayName = "leave"
			screen_loc = "9:-8, 6:8"
			Click()
				. = ..()
				var /interface/characterSelect/gameInt = usr
				if(!istype(gameInt)) return
				sleep(3)
				gameInt.leave()
		toggle
			displayName = "add"
			var
				team
			Click()
				. = ..()
				var /interface/characterSelect/gameInt = usr
				if(!istype(gameInt)) return
				if(gameInt.character)
					gameInt.detachCharacter()
				else
					gameInt.game.addCharacter(gameInt, team)
		cpu
			displayName = "cpu"
			var
				team
			Click()
				. = ..()
				var /interface/characterSelect/gameInt = usr
				if(!istype(gameInt)) return
				gameInt.game.addCPU(team)

//-- Change Character ----------------------------
character/Click()
	. = ..()
	var /interface/characterSelect/clickUser = usr
	if(!istype(clickUser)) return
	if(istype(player, /interface/characterSelect) && player != clickUser) return
	var /game/ownGame = game(src)
	ASSERT(player)
	ownGame.changeCharacter(player)


//-- Gameplay - Control Character during game -----------------------------

interface/gameplay
	//showGameChat = TRUE
	var
		character/character
	New(client/newClient, character/newCharacter)
		. = ..()
		attachCharacter(newCharacter)
		var /game/newGame = game(character)
		loc = locate(newGame.x, newGame.y, newGame.z)

	attachCharacter(newCharacter)
		character = newCharacter
		character.player = src
	control(character/controlChar)
		return client.macros.commands
