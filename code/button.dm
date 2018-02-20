

//-- Button ---------------------------------------------------------------

button
	parent_type = /obj
	icon = 'gameplay_buttons.dmi'
	bound_width  = 64
	bound_height = 32
	plane = PLANE_BUTTON
	var
		displayName
	New()
		. = ..()
		icon_state = "[displayName]_up"
	Click()
		. = ..()
		spawn()
			icon_state = "[displayName]_down"
			sleep(2)
			icon_state = "[displayName]_up"

	resultsDone
		parent_type = /button
		displayName = "done"
		screen_loc = "8:8,1:8"
		Click()
			. = ..()
			usr.client.screen.Remove(src)
			system.titleScreen.addPlayer(usr.client)
