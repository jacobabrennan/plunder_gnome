

//-------------------------------------------------------------------------------
/*
mob
	icon_state = "mob"
	verb
		astartest()
			Clear()
			var/turf/dest = locate(/obj/dest)
			dest = dest.loc
			var/path[] = pather.aStar(loc,dest)
			for(var/turf/t in path)
				t.icon_state = "blue"

		dijkstratest()
			Clear()
			var/path[] = pather.dijkstra(loc)
			for(var/turf/t in path)
				t.icon_state = "blue"

		dijkstratestall()
			Clear()
			var/paths[] = pather.dijkstra(loc, , 0)
			for(var/list/path in paths)
				for(var/turf/t in path)
					t.icon_state = "blue"

		dijkstratestrange()
			Clear()
			var/path[] = pather.dijkstraInRange(loc, P_INCLUDE_INTERIOR)
			for(var/turf/t in path)
				t.icon_state = "blue"

		clear()
			Clear()

proc
	Clear()
		for(var/turf/t)
			t.icon_state = initial(t.icon_state)

	//Done after running into the first destination object
	//Finished(turf/t)
	//	return (locate(/obj/dest) in t) ? P_DIJKSTRA_FINISHED : P_DIJKSTRA_NOT_FOUND

	//Done after moving 5 units of range
	RangeFinished(turf/t, range)
		return range > 5

	//Find paths to all the destination objects
	//FinishedAll(turf/t)
	//	return (locate(/obj/dest) in t) ? P_DIJKSTRA_ADD_PATH : P_DIJKSTRA_NOT_FOUND
*/

atom/var/pathweight = 1

//------------------------------------------------
#define P_DIJKSTRA_NOT_FOUND 0
#define P_DIJKSTRA_FINISHED 1
#define P_DIJKSTRA_ADD_PATH 2
#define P_INCLUDE_INTERIOR 1
#define P_INCLUDE_FINISHED 2


//-- Path finding, originally from Theodis.pathfinder ---------------------------

path
	var
		callAdjacent
		callDistance
		callFinished
		finishedGoal
	New(adjacent, distance, finished)
		callAdjacent = adjacent || "adjacentTurfs"
		callDistance = distance || "atomicDistance"
		if(ispath(finished) || istype(finished, /atom))
			callFinished = "findType"
			finishedGoal = finished
		else
			callFinished = finished //|| /proc/RangeFinished


//-- Main Path Finding Functions -----------------------------------------------

path
	proc
		//------------------------------------------------
		aStar(start, end, maxnodes, maxnodedepth, mintargetdist, minnodedist)
			// Configure priority queue, node lists, and path
			var compareFunction = /path/proc/PathWeightCompare
			var /path/PriorityQueue/open = new(compareFunction)
			var /list/closed = list()
			var /list/path
			nodeCosts = new()
			// Expand nodes according to heuristic until target is reached
			open.Enqueue(generateNode(start, null, 0, distance(start, end)))
			while(!open.IsEmpty() && !path)
				// Get the next node (the lowest value)
				var/path/node/currentNode = open.Dequeue()
				closed.Add(currentNode.source)
				//
				var/closeenough
				if(mintargetdist)
					closeenough = distance(currentNode.source, end) <= mintargetdist
				if(currentNode.source == end || closeenough) //Found the path
					path = new()
					path.Add(currentNode.source)
					while(currentNode.prevNode)
						currentNode = currentNode.prevNode
						path.Add(currentNode.source)
					break
				//
				if(maxnodedepth)
					if(minnodedist)
						if(call(currentNode.source, minnodedist)(end) + currentNode.nodesTraversed >= maxnodedepth)
							continue
					else
						if(currentNode.nodesTraversed >= maxnodedepth)
							continue
				// Add adjacent nodes to the list of nodes to be checked (open nodes)
				var /list/adjacentNodes = adjacent(currentNode.source)
				for(var/datum/adjacentNode in adjacentNodes)
				// Skip the adjacent node if another path can reach it for less cost
					var cost = currentNode.costCurrent + distance(currentNode.source, adjacentNode)
					var previousCost = nodeCosts[adjacentNode]
					if(previousCost)
						if(cost + distance(adjacentNode, end) >= previousCost) continue
				// Remove any previously found higher cost nodes.
						for(var/I = 1 to open.L.len)
							var/path/node/previousNode = open.L[I]
							if(previousNode.source == adjacentNode)
								open.Remove(I)
								break
				// Add the adjacent node to the open nodes list
					open.Enqueue(generateNode(adjacentNode, currentNode, cost, distance(adjacentNode, end), currentNode.nodesTraversed+1))
					if(maxnodes && open.L.len > maxnodes)
						open.L.Cut(open.L.len)
			nodeCosts = null
			// Put path in order of start to finish by reversing
			if(path)
				for(var/I = 1; I <= path.len/2; I++)
					path.Swap(I, path.len-I+1)
			// Return the resulting path
			return path

		//------------------------------------------------
		dijkstra(start, maxnodedepth, compatibility=1)
			// Configure priority queue, node lists, and paths
			var compareFunction = /path/proc/PathWeightCompare
			var /path/PriorityQueue/open = new(compareFunction)
			var /list/closed = new()
			var /list/resultPaths = new()
			var /list/foundPath
			nodeCosts = new()
			// Expand out from start until a goal is found, or there are no more open nodes
			open.Enqueue(generateNode(start, null, 0, 0))
			while(!open.IsEmpty())
				// Get the next node (the lowest value)
				var /path/node/currentNode = open.Dequeue()
				closed.Add(currentNode.source)
				// If this node is a goal then add its path to the resultPaths
				var isDone = finished(currentNode.source, currentNode.costCurrent)
				if(isDone)
				// Construct the path by traversing the node linked list
					var /path/node/tmpNode = currentNode
					foundPath = new()
					foundPath.Add(tmpNode.source)
					while(tmpNode.prevNode)
						tmpNode = tmpNode.prevNode
						foundPath.Add(tmpNode.source)
				// Append the path to the results list
				// (Do not use Add() to append a list to a list)
					resultPaths.len++
					resultPaths[resultPaths.len] = foundPath
				// Determine if we're done finding paths, or if we should find more.
				if(isDone == P_DIJKSTRA_FINISHED) break
				// Move on to the next node if this one is at max depth
				if(maxnodedepth && currentNode.nodesTraversed >= maxnodedepth) continue
				// Add adjacent nodes to the open list
				expandAdjacentNodes(currentNode, open)
			// Once a path has been found or there are no more open nodes, continue
			nodeCosts = null
			// Put paths in order of start to finish, by reversing each found path
			for(var/list/individualPath in resultPaths)
				for(var/I = 1; I <= individualPath.len/2; I++)
					individualPath.Swap(I, individualPath.len-I+1)
			// Return the resulting path or paths
			if(!resultPaths.len)
				return null
			else if(resultPaths.len == 1 && compatibility)
				return resultPaths[1]
			return resultPaths

		//------------------------------------------------
		dijkstraInRange(start, include = (P_INCLUDE_INTERIOR | P_INCLUDE_FINISHED), maxnodedepth)
			// Configure priority queue, node lists, and path
			var compareFunction = /path/proc/PathWeightCompare
			var /path/PriorityQueue/open = new(compareFunction)
			var /list/closed = list()
			var /list/path = list()
			var /list/finishedL = list()
			nodeCosts = new()
			// Expand out from start until a goal is found, or there are no more open nodes
			open.Enqueue(generateNode(start,null,0,0))
			while(!open.IsEmpty())
				// Get the next node (the lowest value)
				var/path/node/currentNode = open.Dequeue()
				closed.Add(currentNode.source)
				//
				if(finished(currentNode.source, currentNode.costCurrent)) //Found an end point
					finishedL += currentNode.source
					continue
				// Move on to the next node if this one is at max depth
				if(maxnodedepth && currentNode.nodesTraversed >= maxnodedepth) continue
				// Add adjacent nodes to the open list
				expandAdjacentNodes(currentNode, open)
			// Once a path has been found or there are no more open nodes, continue
			nodeCosts = null
			//
			for(var/datum/enclosed in closed)
				path.Add(enclosed)
			//
			switch(include)
				if(P_INCLUDE_INTERIOR)
					return path
				if(P_INCLUDE_FINISHED)
					return finishedL
				if(P_INCLUDE_INTERIOR | P_INCLUDE_FINISHED)
					return path + finishedL
			return null


//-- Utilities -----------------------------------------------------------------

//-- Node Handling -------------------------------
path
	var
		list/nodeCosts
	node
		parent_type = /datum
		var
			datum/source
			path/node/prevNode
			costProjected
			costCurrent
			costHeuristic
			nodesTraversed
		New(s,p,pg,ph,pnt)
			source = s
			prevNode = p
			costCurrent = pg
			costHeuristic = ph
			costProjected = costCurrent + costHeuristic
			nodesTraversed = pnt

	proc
		generateNode(s,p,pg,ph,pnt)
			var /path/node/newNode = new(s,p,pg,ph,pnt)
			ASSERT(newNode)
			ASSERT(newNode.source)
			nodeCosts[newNode.source] = newNode.costProjected
			return newNode

		PathWeightCompare(path/node/node1, path/node/node2)
			return node1.costProjected - node2.costProjected

		expandAdjacentNodes(path/node/currentNode, path/PriorityQueue/open)
			// Add adjacent nodes to the list of nodes to be checked (open nodes)
			var /list/adjacentNodes = adjacent(currentNode.source)
			for(var/datum/adjacentNode in adjacentNodes)
			// Skip the adjacent node if another path can reach it for less cost
				var cost = currentNode.costCurrent + distance(currentNode.source, adjacentNode)
				var previousCost = nodeCosts[adjacentNode]
				if(previousCost)
					if(cost >= previousCost) continue
			// Remove any previously found higher cost nodes.
					for(var/I = 1 to open.L.len)
						var/path/node/previousNode = open.L[I]
						if(previousNode.source == adjacentNode)
							open.Remove(I)
							break
			// Add the adjacent node to the open nodes list and move on to the next open node
				open.Enqueue(generateNode(adjacentNode, currentNode, cost, 0, currentNode.nodesTraversed+1))


//-- Dynamic Function Calling --------------------
path
	proc
		adjacent()
			if(hascall(src, callAdjacent))
				return call(src, callAdjacent)(arglist(args))
			else
				return call(callAdjacent)(arglist(args))
		distance()
			if(hascall(src, callDistance))
				return call(src, callDistance)(arglist(args))
			else
				return call(callDistance)(arglist(args))
		finished()
			if(hascall(src, callFinished))
				return call(src, callFinished)(arglist(args))
			else
				return call(callFinished)(arglist(args))
	proc
		adjacentTurfs(turf/centralTurf)
			// Also add objs, because we need to be able to target them
			if(!isturf(centralTurf)) return list()
			var /list/adjacent = list()
			if(!centralTurf.density)
				for(var/turf/adjacentTurf in orange(centralTurf, 1))
					adjacent.Add(adjacentTurf)
					adjacent.Add(adjacentTurf.contents)
			return adjacent
		atomicDistance(atom/atom1, atom/atom2)
			if(get_dist(atom1, atom2) != 1)
				return get_dist(atom1, atom2)
			else
				var cost = (atom1.x - atom2.x)**2 + (atom1.y - atom2.y)**2
				//Multiply the cost by the average of the pathweights of the
				//tile being entered and tile being left
				cost *= (atom1.pathweight + atom2.pathweight)/2
				return cost
		findType(datum/testDatum)
			if(locate(finishedGoal) in testDatum) return P_DIJKSTRA_FINISHED
			if(finishedGoal == testDatum) return P_DIJKSTRA_FINISHED
			diag(testDatum)
			return P_DIJKSTRA_NOT_FOUND


//-- Priority Queue, from Theodis.PriorityQueue --
path
	PriorityQueue
		parent_type = /datum
		var
			L[]
			cmp
		New(compare)
			L = new()
			cmp = compare
		proc
			IsEmpty()
				return !L.len
			Enqueue(d)
				var/i
				var/j
				L.Add(d)
				i = L.len
				j = i>>1
				while(i > 1 &&  call(cmp)(L[j],L[i]) > 0)
					L.Swap(i,j)
					i = j
					j >>= 1

			Dequeue()
				ASSERT(L.len)
				. = L[1]
				Remove(1)

			Remove(i)
				ASSERT(i <= L.len)
				L.Swap(i,L.len)
				L.Cut(L.len)
				if(i < L.len)
					_Fix(i)
			_Fix(i)
				var/child = i + i
				var/item = L[i]
				while(child <= L.len)
					if(child + 1 <= L.len && call(cmp)(L[child],L[child + 1]) > 0)
						child++
					if(call(cmp)(item,L[child]) > 0)
						L[i] = L[child]
						i = child
					else
						break
					child = i + i
				L[i] = item
			List()
				var/ret[] = new()
				var/copy = L.Copy()
				while(!IsEmpty())
					ret.Add(Dequeue())
				L = copy
				return ret
			RemoveItem(i)
				var/ind = L.Find(i)
				if(ind)
					Remove(ind)