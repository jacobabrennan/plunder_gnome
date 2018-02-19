

//-- Title Screen --------------------------------------------------------------

interface/titleScreen
	var
		interface/titleScreen/join/joinButton
		joining
	Login()
		.=..()
		loc = locate(TITLE_SCREEN_LOCATION)
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
			system.nextGame.addPlayer(client)
	join
		parent_type = /button
		displayName = "join"
		screen_loc = "8:8,6:8"
		Click()
			. = ..()
			var /interface/titleScreen/title = usr
			if(istype(title))
				title.join()