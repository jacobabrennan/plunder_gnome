

//-- Global Defines ------------------------------------------------------------


//-- Language Definitions ------------------------------------------------------
/*
the Program - A running instance of this project. A "BYOND world".
Game - An instance of /game
User - A human interacting with the program in any state
Player - A human or AI controller character instance in a game instance
*/

//-- Teams - Must be valid color names -----------------------------------------
#define TEAM_RED "red"
#define TEAM_BLUE "blue"
#define TEAM_GREEN "green"
#define TEAM_YELLOW "yellow"


//-- Gameplay Metrics ----------------------------------------------------------

#define PRIMARY 1
#define TICK_DELAY (1/2)
	// The number of radishes a character can carry
#define DELAY_PLUNDER 5
	// How long it takes for a character to plunder a radish
#define TIME_STUN 40
	// How long a player remains stunned
#define TIME_INVULNERABLE 20
	// How long a player is invulnerable after being stunned
#define MAX_VELOCITY 6


//-- Display Metrics -----------------------------------------------------------

#define PLANE_BUTTON 2


//-- Mapping System ------------------------------------------------------------

//-- Map Metrics ---------------------------------
#define TILE_SIZE 16
	// The width/height of a Tile, like a turf or the standard size of an atom/movable
#define TITLE_SCREEN_LOCATION "title_location"
#define MAP_GAMES_OFFSET 4
	// The z coordinate at which the first game instance is loaded.

//-- Movement Flags ------------------------------
#define MOVEMENT_NONE 0
#define MOVEMENT_FLOOR 1
#define MOVEMENT_WATER 2
#define MOVEMENT_WALL 4
#define MOVEMENT_ALL 7

//-- Interaction Flags----------------------------
#define INTERACTION_NONE 0
#define INTERACTION_0000000000000001 1
#define INTERACTION_0000000000000010 2
#define INTERACTION_0000000000000100 4
#define INTERACTION_0000000000001000 8
#define INTERACTION_0000000000010000 16
#define INTERACTION_0000000000100000 32
#define INTERACTION_0000000001000000 64
#define INTERACTION_0000000010000000 128
#define INTERACTION_0000000100000000 256
#define INTERACTION_0000001000000000 512
#define INTERACTION_0000010000000000 1024
#define INTERACTION_0000100000000000 2048
#define INTERACTION_0001000000000000 4096
#define INTERACTION_0010000000000000 8192
#define INTERACTION_0100000000000000 16384
#define INTERACTION_1000000000000000 32768
