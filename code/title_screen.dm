

//-- Title Screen --------------------------------------------------------------

interface/titleScreen
	Login()
		.=..()
		loc = locate(TITLE_SCREEN_LOCATION)
	Logout()
		.=..()
		Del()
	proc
		spectate()
			var /game/game = pick(system.games)
			game.addSpectator(client)
		joinTeam(teamColor)
			system.nextGame.addPlayer(client, teamColor)

//------------------------------------------------
interface/titleScreen

	button
		parent_type = /obj
		icon = 'game_status.dmi'
		layer = 5
		join_red
			Click()
				var /interface/titleScreen/title = usr
				title.joinTeam(TEAM_RED)
			left
				icon_state = "join_red_1"
			center
				icon_state = "join_red_2"
			right
				icon_state = "join_red_3"
		join_blue
			Click()
				var /interface/titleScreen/title = usr
				title.joinTeam(TEAM_BLUE)
			left
				icon_state = "join_blue_1"
			center
				icon_state = "join_blue_2"
			right
				icon_state = "join_blue_3"