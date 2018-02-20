

//-- System --------------------------------------------------------------------

#define diag(messages...) system.diagnostic(list(messages), __FILE__, __LINE__)
var/system/system = new()
system
	var
		// Version Info. These three variables are set in version_history.dm
		versionType = "Internal"
		versionNumber = "-.-"
		versionHub = -1
		// Hub Info
		author = "Jacob A. Brennan"
		authorHub = "IainPeregrine"
		gameName = "Plunder Gnome"
		gameHub = "iainperegrine.plundergnome"
		passwordHub = SECURE_HUB_PASSWORD

	New()
		. = ..()
		system = src
		spawn()
			startProject()

	//-- System State Management ---------------------
	var
		_ready = FALSE
		list/_waitingClients = new() // When the world boots, clients are put in here until the system is ready.
		titleScreen/titleScreen
	proc
		startProject()
			diag("<b>----- System Starting -----</b>")
			loadVersion()
			loadHub()
			nextGame = newGame()
			diag("<b>----- Loading Title -----</b>")
			titleScreen = new()
			diag("<b>----- System Ready -----</b>")
			_ready = TRUE
			for(var/client/C in _waitingClients)
				registerPlayer(C)
		loadHub()
			world.version = versionHub
			world.name = gameName
			world.hub = gameHub
			world.hub_password = passwordHub
		restart()
			diag("<b>---- System Restarting ----</b>")
			world << "<hr>"
			world.Reboot()

	//-- Development Utilities -----------------------
	proc
		diagnostic(list/messages, file, line)
			var argText = ""
			var first = TRUE
			for(var/key in messages)
				if(!first)
					argText += ", "
				first = FALSE
				argText += "[key]"
			world << {"<span style="color:grey">[file]:[line]::</span> <b>[argText]</b>"}
			world << output({"<span style="color:grey">[file]:[line]::</span> <b>[argText]</b>"}, "outputChannelGame")

	//-- Game Management -----------------------------
	var
		game/nextGame
		list/games = new()
		list/mapSlots = new()
	proc

		//-- RegisterGame - Store, & allocate map space --
		registerGame(game/newGame)
			// Allocate Space
			var slotIndex
			for(var/index = 1 to mapSlots.len)
				if(!mapSlots[index])
					slotIndex = index
					break
			if(!slotIndex)
				slotIndex = ++mapSlots.len
			mapSlots[slotIndex] = newGame
			// Inform game about its map placement (Set zOffset on game)
			newGame.zPosition = (MAP_GAMES_OFFSET-1) + slotIndex
			// Increase world size if necessary
			world.maxz = max(world.maxz, newGame.zPosition)
			// Assign Id & Store for later retrieval
			newGame.gameId = "game[slotIndex]"
			games[newGame.gameId] = newGame

		//-- DeregisterGame - Remove, & free map space ---
		deregisterGame(game/oldGame)
			// Remove game from games list
			games.Remove(oldGame)
			// Remove game from mapSlots
			var slotIndex
			for(var/index = 1 to mapSlots.len)
				if(mapSlots[index] == oldGame)
					slotIndex = index
					mapSlots[slotIndex] = null
					break
			// Shrink World, if possible
			if(slotIndex == mapSlots.len)
				while(mapSlots.len && !mapSlots[mapSlots.len])
					mapSlots.len = mapSlots.len-1
			var maxZPosition = (MAP_GAMES_OFFSET-1) + mapSlots.len
			world.maxz = min(world.maxz,  maxZPosition)

		//-- GetGame - Retrieve instance by ID -----------
		getGame(gameId)
			return games[gameId]

		//-- NewGame - Create new game instance ----------
		newGame()
			var /game/newGame = new()
			registerGame(newGame)
			mapManager.loadMap(newGame)
			newGame.setup()
			return newGame

		//-- DelGame - Clean up and delete game instance -
		delGame(gameId)
			var /game/oldGame = getGame(gameId)
			if(!oldGame) return
			deregisterGame(oldGame)
			mapManager.unloadMap(oldGame)
			del oldGame

		//-- StartGame - Start game and setup next game --
		startGame()
			var success = nextGame.start()
			if(!success) return
			nextGame = newGame()

	//-- Player Handling -----------------------------
	proc
		registerPlayer(client/client) // Called by /interface/clay/New()
			if(!_ready)
				_waitingClients.Add(client)
				spawn(1)
					diag("System is Loading")
				return
			// Check games in progress for disconnected player?
			// Send player to title screen
			titleScreen.addPlayer(client)

	//-- Map Manager ---------------------------------
	var
		system/mapManager/mapManager = new()
	mapManager
		parent_type = /dmm_suite
		var/list/gameMaps = list(
			'maps/farm_4.dmm',
			'maps/farm_double.dmm',
			'maps/farm_double.dmm',
			'maps/farm_double.dmm',
			//'maps/farm_bubble.dmm',

			'maps/snow_slide.dmm',

			'maps/river_1.dmm',
			'maps/river_1.dmm',

			'maps/river_2.dmm',
			'maps/river_2.dmm',
		)
		proc
			loadMap(game/gameArea, mapFile)
				// Load atomic map objects from file
				if(!mapFile)
					mapFile = pick(gameMaps)
				load_map(mapFile, gameArea.zPosition)
				// Add all map objects to the game area
				gameArea.contents.Add(block(
					locate(         1,          1, gameArea.zPosition),
					locate(world.maxx, world.maxy, gameArea.zPosition)
				))
			unloadMap(game/gameArea)
				// Move all user's interfaces off the map
				for(var/interface/player in gameArea.contents)
					player.forceLoc(null)
				// Delete all atomic map objects
				for(var/atom/gameContent in gameArea.contents)
					del gameContent

