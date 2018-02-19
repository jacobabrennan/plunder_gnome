

//-- Team - Coordinating object for teams & team member AI ---------------------

team
	var
		color
		score = 0
		list/characters = new()
		// Map Awareness
		tile/goal/goal
		list/farms = new()
	New(teamColor)
		. = ..()
		color = teamColor