

//-- Button ---------------------------------------------------------------

button
	parent_type = /obj
	icon = 'gameplay_buttons.dmi'
	bound_width  = 64
	bound_height = 32
	layer = FLY_LAYER
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