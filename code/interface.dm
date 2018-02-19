

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
	New(client/_client)
		// don't do the default action: place interface inside of first argument
		if(_client) client = _client
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
	showGameChat = TRUE


//-- Round Setup ----------------------------------------------------------

interface/characterSelect
	showGameChat = TRUE
	var
		game/game
		character/character
	New(client/newClient, game/newGame)
		game = newGame
		loc = locate(game.x, game.y, game.z)
		. = ..()
	proc
		attachCharacter(newCharacter)
			if(!character)
				for(var/button/cpuButton in cpu)
					client.screen.Add(cpuButton)
				buttonLeave.screen_loc = "11:-4, 6:8"
				client.screen.Add(buttonStart)
			character = newCharacter
			character.player = src
			character.name = html_encode(key)

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
			teamCPU.screen_loc = "[teamPlacement.x+offset], [teamPlacement.y-1]"
			cpu.Add(teamCPU)
			//
			var /interface/characterSelect/button/toggle/teamToggle = new()
			teamToggle.team = teamColor
			switch(teamColor)
				if(TEAM_RED   ) teamToggle.color = list("#f00", "#fff", "#000")
				if(TEAM_BLUE  ) teamToggle.color = list("#33f", "#fff", "#000")
				if(TEAM_GREEN ) teamToggle.color = list("#6f0", "#fff", "#000")
				if(TEAM_YELLOW) teamToggle.color = list("#fc0", "#fff", "#000")
			teamToggle.screen_loc = "[teamPlacement.x-1], [teamPlacement.y-1]"
			toggle.Add(teamToggle)
			//
			client.screen.Add(teamToggle)

	Logout()
		del buttonStart
		del buttonLeave
		for(var/button/loopButton in cpu+toggle)
			del loopButton
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
				new /interface/titleScreen(gameInt.client)
		toggle
			displayName = "add"
			var
				team
			Click()
				. = ..()
				var /interface/characterSelect/gameInt = usr
				if(!istype(gameInt)) return
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


//-- Gameplay - Control Character during game -----------------------------

interface/gameplay
	showGameChat = TRUE
	var
		character/character
	New(client/newClient, character/newCharacter)
		return
		. = ..()
		attachCharacter(newCharacter)
		var /game/newGame = game(character)
		loc = locate(newGame.x, newGame.y, newGame.z)
	proc
		attachCharacter(newCharacter)
			character = newCharacter
			character.player = src
	control(character/controlChar)
		return client.macros.commands


//-- Results - displays results of game -----------------------------------

interface/results
	showGameChat = TRUE
	Login()
		. = ..()
		spawn(10)
			new /interface/clay(client)
