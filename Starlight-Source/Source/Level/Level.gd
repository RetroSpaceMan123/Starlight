extends Node2D

const N = 1
const E = 2
const S = 4
const W = 8

var cell_walls = {Vector2(0, -2): N, Vector2(2, 0): E, 
				  Vector2(0, 2): S, Vector2(-2, 0): W}

var tile_size = 32  # tile size (in pixels)
var width = 40  # width of map (in tiles)
var height = 40 # height of map (in tiles)

var scroll = 3 # camera zoom

var map_seed # map seed

var erase = 0.2 # fraction of walls to remove

# get a reference to the map for convenience
onready var Map = $TileMap
onready var Cam = $Camera2D

func _ready():
	Cam.zoom = Vector2(scroll, scroll)
	Cam.offset = Map.map_to_world(Vector2(width/2, height/2))
	randomize()
	if map_seed != 0:
		map_seed = randi()
	seed(map_seed)
	print("Seed:", map_seed)
	tile_size = Map.cell_size
	make_maze()
	erase_walls()
	
func _process(delta):
	if scroll > 1:
		if Input.is_action_pressed("scroll_up"):
			scroll -= .5
			Cam.zoom = Vector2(scroll, scroll)
		if Input.is_action_pressed("scroll_down"):
			scroll += .5
			Cam.zoom = Vector2(scroll, scroll)
	elif scroll <= 1:
		if Input.is_action_pressed("scroll_down"):
			scroll += 1
			Cam.zoom = Vector2(scroll, scroll)

func check_neighbors(cell, unvisited):
	# returns an array of cell's unvisited neighbors
	var list = []
	for n in cell_walls.keys():
		if cell + n in unvisited:
			list.append(cell + n)
	return list
	
func make_maze():
	var unvisited = []  # array of unvisited tiles
	var stack = []
	# fill the map with solid tiles
	Map.clear()
	for x in range(width):
		for y in range(height):
			Map.set_cellv(Vector2(x, y), N|E|S|W)
	for x in range(0, width, 2):
		for y in range(0, height, 2):
			unvisited.append(Vector2(x, y))
	var current = Vector2(0, 0)
	unvisited.erase(current)
	# execute recursive backtracker algorithm
	while unvisited:
		var neighbors = check_neighbors(current, unvisited)
		if neighbors.size() > 0:
			var next = neighbors[randi() % neighbors.size()]
			stack.append(current)
			# remove walls from *both* cells
			var dir = next - current
			var current_walls = Map.get_cellv(current) - cell_walls[dir]
			var next_walls = Map.get_cellv(next) - cell_walls[-dir]
			Map.set_cellv(current, current_walls)
			Map.set_cellv(next, next_walls)
			# insert connection tile
			if dir.x != 0:
				Map.set_cellv(current + dir/2, 5)
			else:
				Map.set_cellv(current + dir/2, 10)
			current = next
			unvisited.erase(current)
		elif stack:
			current = stack.pop_back()


func erase_walls(): # randomly erases walls
	for i in range(int(width * height * erase)):
		var x = int(rand_range(1, width - 1))
		var y = int(rand_range(1, height - 1))
		var cell = Vector2(x, y)
		var neighbor = cell_walls.keys()[randi() % cell_walls.size()]
		if Map.get_cellv(cell) & cell_walls[neighbor]:
			var walls = Map.get_cellv(cell) - cell_walls[neighbor]
			var n_walls = Map.get_cellv(cell+neighbor) - cell_walls[-neighbor]
			Map.set_cellv(cell, walls)
			Map.set_cellv(cell+neighbor, n_walls)
