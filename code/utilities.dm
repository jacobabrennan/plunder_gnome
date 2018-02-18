

//-- Development Utilities -----------------------------------------------------

#define TAG #warn Unfinished
client/verb/forceReboot()
	world.Reboot()


//-- Graphic Utilities ---------------------------------------------------------

proc/getAppearance(displayable)
	var /obj/base = new()
	base.overlays.Add(displayable)
	for(var/newAppearance in base.overlays)
		return newAppearance


//-- Math Utilities ------------------------------------------------------------

proc
	exp(power)
		return e**power
	atan2(X, Y)
		if(!X && !Y) return 0
		return Y >= 0 ? arccos(X / sqrt(X * X + Y * Y)) : -arccos(X / sqrt(X * X + Y * Y))
	ceil(N)
		return -round(-N)
	fix_angle(var/theta as num)
		theta = round(theta)%360+(theta-round(theta))
		if(theta<0)
			theta+=360
		return theta

proc
	coord(x, y, z) return new /coord(x, y, z)
	vector(_m, _d) return new /vector(_m, _d)

coord
	var
		x
		y
		z
	New(newX, newY, newZ)
		x = newX
		y = newY
		z = newZ
	toJSON()
		var/list/objectData = ..()
		objectData["x"] = x
		objectData["y"] = y
		if(z != null) objectData["z"] = z
		return objectData
	fromJSON(list/objectData)
		x = objectData["x"]
		y = objectData["y"]
		if(objectData["z"]) z = objectData["z"]
	//
	proc/copy()
		return new type(x, y, z)
	proc/place(atom/movable/M)
		return M.forceLoc(locate(x, y, z))
	// Operator Redefinition
	proc
		operator+(coord/addCoord)
			return new /coord(x + addCoord.x, y + addCoord.y, z + addCoord.z)
		operator-(coord/addCoord)
			return new /coord(x - addCoord.x, y - addCoord.y, z - addCoord.z)
		operator*(coord/addCoord)
			return new /coord(x * addCoord.x, y * addCoord.y, z * addCoord.z)
		operator/(coord/addCoord)
			return new /coord(x / addCoord.x, y / addCoord.y, z / addCoord.z)
vector
	var
		mag
		dir
	New(newM,newD)
		mag = newM
		dir = newD
	toJSON()
		var/list/objectData = ..()
		objectData["mag"] = mag
		objectData["dir"] = dir
		return objectData
	fromJSON(list/objectData)
		mag = objectData["mag"]
		dir = objectData["dir"]
	proc/copy()
		return new /vector(mag,dir)
	proc/from(atom/movable/start, atom/movable/end)
		var deltaX = (end.x*TILE_SIZE + end.step_x + end.bound_width /2) - (start.x*TILE_SIZE + start.step_x + start.bound_width /2)
		var deltaY = (end.y*TILE_SIZE + end.step_y + end.bound_height/2) - (start.y*TILE_SIZE + start.step_y + start.bound_height/2)
		mag = sqrt(deltaX*deltaX + deltaY*deltaY)
		if(mag)
			dir = atan2(deltaX, deltaY)
			rotate(0)
	proc/rotate(degrees)
		dir += degrees
		while(dir < 0) dir += 360
		while(dir >= 360) dir -= 360


//-- Saving / Loading Utilities ------------------------------------------------

proc/replaceFile(filePath, fileText)
	if(fexists(filePath)) fdel(filePath)
	return text2file(fileText, filePath)

datum/proc/toJSON() // hook
	var/jsonObject = list()
	jsonObject["typePath"] = type
	return jsonObject

datum/proc/fromJSON(list/objectData) // hook

proc
	json2Object(list/objectData) // utility
		// Handle Primitive Types (strings, numbers, null)
		if(!istype(objectData))
			return objectData
		// Handle objects from toJSON (having entries for "typepath")
		var/typePath = text2path(objectData["typePath"])
		if(typePath)
			var/datum/D = new typePath()
			D.fromJSON(objectData)
			return D
		// Handle Lists (recursive)
		return json2List(objectData)
	json2List(list/objectData)
		var /list/objectList = new()
		for(var/data in objectData)
			var newObject = json2Object(data)
			objectList.Add(newObject)
		return objectList
	list2JSON(list/array) // utility
		var/list/jsonList = new(array.len)
		for(var/I = 1 to array.len)
			var/datum/indexed = array[I]
			if(istype(indexed))
				jsonList[I] = indexed.toJSON(indexed)
			else
				jsonList[I] = json_encode(indexed)
		return jsonList
