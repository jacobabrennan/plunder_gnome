

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
		//if(lagoutTimer) del lagoutTimer
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
	/*	del lagoutTimer
		if(key)
			lagoutTimer = new(src)
		else*/
		del src
/*	lagoutTimer
		parent_type = /datum
		New(interface/lagInt)
			spawn (TIME_LAG_DISCONNECT)
				if(lagInt.lagoutTimer == src)
					del lagInt*/

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

//-- Character Select ----------------------------
interface/characterSelect
	showGameChat = TRUE
	var
		character/character
	New(client/newClient, character/newCharacter)
		. = ..()
		attachCharacter(newCharacter)
		var /game/newGame = game(character)
		loc = locate(newGame.x, newGame.y, newGame.z)
	proc
		attachCharacter(newCharacter)
			character = newCharacter
			character.player = src
			character.name = html_encode(key)

	//-- Buttons -------------------------------------
	var
		interface/characterSelect/button/start/buttonStart
		interface/characterSelect/button/leave/buttonLeave
	verb
		StartGame()
			set name = "Start"
			client.screen.Cut()
			system.startGame()
	Login()
		. = ..()
		buttonStart = new()
		buttonLeave = new()
		client.screen.Add(buttonStart, buttonLeave)
	Logout()
		del buttonStart
		del buttonLeave
		. = ..()
	button
		parent_type = /obj
		icon = 'gameplay_buttons.dmi'
		bound_width  = 64
		bound_height = 32
		start
			icon_state = "start_up"
			screen_loc = "6:4, 6:8"
			Click()
				var /interface/characterSelect/gameInt = usr
				if(!istype(gameInt)) return
				icon_state = "start_down"
				sleep(2)
				icon_state = "start_up"
				spawn(1)
					gameInt.StartGame()
		leave
			icon_state = "leave_up"
			screen_loc = "11:-4, 6:8"
			Click()
				var /interface/characterSelect/gameInt = usr
				if(!istype(gameInt)) return
				icon_state = "leave_down"
				sleep(2)
				icon_state = "leave_up"
				spawn(1)
					new /interface/titleScreen(gameInt.client)

//-- Gameplay - Control Character during game ----
interface/gameplay
	showGameChat = TRUE
	var
		character/character
	New(client/newClient, character/newCharacter)
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


//-- Results - displays results of game ----------
interface/results
	showGameChat = TRUE
	Login()
		. = ..()
		spawn(10)
			new /interface/clay(client)
