
//-- Chat Toggle ---------------------------------
/*
client
	var
		is_chat_visible = TRUE

		toggle_chat()
			set name = ".togglechat"
			is_chat_visible = !is_chat_visible
			winshow(src, "chat", is_chat_visible)

		focus_chat()
			set name = ".focuschat"
			var/chat = winget(src, "chat", "is-visible")
			var/visi = winget(src, "chat.input", "focus")
			if(chat != "true")
				winshow(src, "chat")

			if(visi == "true")
				winset(src, null, "main.focus='true';")

			else
				winset(src, null, "chat.input.focus='true';")*/


//-- Social Systems - Chat & Traffic -------------------------------------------

client
	New()
		. = ..()
		winset(src, "chatSystem", "focus=true")
	Click()
		. = ..()
		winset(src, "chatSystem", "focus=true")

//-- System Chat & Traffic -----------------------
system
	proc
		routeChat(client/who, what)
			// Sanitize user name and message
			var sanitizedName = html_encode(who.key)
			what = html_encode(what)
			what = copytext(what, 1, findtext(what, "\n"))
			what = copytext(what, 1, 400)
			if(!length(what)) return
			// Construct & Output message
			what = {"<b style="color:#fff">[sanitizedName]</b>: <span style="color:#fc9">[what]</span>"}
			var /interface/gameplay/player = who.interface
			if(istype(player))
				var iconText = {"<img class="icon" src="\ref[player.character.icon]" iconstate="1" icondir="4">"}
				what = "[iconText] [what]"
			world << what
		routeTraffic(client/who, message)
			// Sanitize user name and message
			var sanitizedName = html_encode(who.key)
			// Construct & Output message
			world << {"<i style="color:#888">[sanitizedName] [message]</i>"}

client
	// Show traffic when leaving or joining the server
	New()
		. = ..()
		system.routeTraffic(src, "has joined the server.")
	Del()
		system.routeTraffic(src, "has left the server.")
	// Server wide Chat
	verb/saySystem(what as text)
		if(!what) return
		system.routeChat(src, what)


//-- Game Chat & Traffic -------------------------
game
	proc
		hear(message)
			src << output(message, "outputChannelGame")

		routeChat(interface/who, what)
			// Sanitize user name and message
			var sanitizedName = html_encode(who.key)
			what = html_encode(what)
			what = copytext(what, 1, findtext(what, "\n"))
			what = copytext(what, 1, 400)
			if(!length(what)) return
			// Construct display message
			what = {"<b style="color:#fff">[sanitizedName]</b>: <span style="color:#fc9">[what]</span>"}
			var /interface/gameplay/player = who
			if(istype(player))
				// Saved in case I need to figure out the html again:
				var iconText = {"<img class="icon" src="\ref[player.character.icon]" iconstate="1" icondir="4">"}
				what = "[iconText] [what]"
			// Output message
			hear(what)

		routeTraffic(client/who, what)
			// Santize user name
			var sanitizedName = html_encode(who.key)
			// Construct display message
			what = {"<i style="color:#888">[sanitizedName] [what]</i>"}
			// Output message
			hear(what)

// Show traffic when users join the game
interface/characterSelect
	New(client/newClient, game/newGame)
		. = ..()
		newGame.routeTraffic(newClient, "[html_encode(newClient.key)] has joined the game.")

// Add Game Chat to users spectating, selecting their character, or playing
interface/characterSelect
	verb/sayGame(what as text)
		if(!what) return
		var /game/G = game(src)
		G.routeChat(src, what)
interface/spectator
	verb/sayGame(what as text)
		if(!what) return
		var /game/G = game(src)
		G.routeChat(src, what)
interface/gameplay
	verb/sayGame(what as text)
		if(!what) return
		var /game/G = game(character)
		G.routeChat(src, what)
