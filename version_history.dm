

//-- Version History, Planned Features, Brainstorming, Notes -------------------

//------------------------------------------------

//------------------------------------------------------------------------------

//345678901234567890123456789012345678901234567890123456789012345678901234567890

// ^ Blank Dividers for easy cut/paste. 80 & 50 characters long.
system
	proc/loadVersion()
		system.versionType = "Internal"
		system.versionNumber = "3.0"
		system.versionHub = 0
		spawn(1)
			world << "<b>Version [versionType] [versionNumber]</b>"



/*-- Feature List --------------------------------------------------------------

Focus - Things which must be done this version
	Git init

Upcomming - Feature candidates for the next version
	AI
	Select other characters (moles, etc)
		With differing weights and speeds
	Find old source with other maps & critters
	Show Plunder Effects
	map selection

Set In Stone - Features that have to be finished for 3.0
	On screen "3, 2, 1, GO!"

Spectulative - Ideas for new features to make the game better.
	radishes visibly "grow" from the ground
	4 teams at once
	Title screen AI Gnome who farms continuously
	Mercy Rule - Auto win if one side has X more points.

Deferred - Low Priority Optional Features


//------------------------------------------------------------------------------

*/
