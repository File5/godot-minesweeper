
extends PanelContainer


var MapSize = Vector2(9,9)
var MineCount = 10

var Time = 0

onready var MapBox = get_node('box/map')
onready var InfoBox = get_node('box/info')

var game_over = false
var tiles_opened = 0





func _ready():
	start()


func start():
	# Hide win/lose labels
	get_node('game_over').hide()
	get_node('win').hide()


	# Draw labels
	InfoBox.get_node('time/amount').set_text(str(Time))
	InfoBox.get_node('mines/amount').set_text(str(MineCount))
	

	make_tiles()
	adjust_window_size()
	distribute_mines()
	

	
func make_tiles():
	# Make tiles
	assert MapBox.get_child_count() == 0
	MapBox.set_columns(MapSize.x)
	for y in range(MapSize.y):
		for x in range(MapSize.x):
			var tile = preload('res://Tile.tscn').instance()
			tile.set_meta('pos', Vector2(x,y))
			MapBox.add_child(tile)
			tile.connect("bomb",self,'_on_hit_mine',[tile])
			tile.connect("opened",self,'_on_tile_opened',[tile.get_meta('pos')])

func adjust_window_size():
	# Adjust window size
	var rect = MapBox.get_child(0).get_rect().size
	var x = rect.width*MapSize.x+48
	var y = (rect.height*MapSize.y)+get_node('box/info').get_rect().size.height+38
	var size = Vector2(x,y)
	OS.set_window_size(size)

func distribute_mines():
	# Distribute mines
	var M = MineCount
	prints("Mines:",M)
	while M > 0:
		var minepos = randi() % int(MapSize.x*MapSize.y)
		if not MapBox.get_child(minepos).mine:
			MapBox.get_child(minepos).mine = true
			M -= 1
	
	# Set mine neighbors
	set_neighbors()





# Start a new game from the newgame dialog
func new_game(W,H,M):
	game_over = false
	MapSize = Vector2(W,H)
	MineCount = M
	tiles_opened = 0
	set_process(false)
	Time = 0
	
	clear_map()
	randomize()
	start()





# Count mine neighbors
func set_neighbors():
	for y in range(MapSize.y):
		for x in range(MapSize.x):
			var o = Vector2(x,y)
			var neighbors = get_neighbors(o)
			var mines = 0
			for tile in neighbors:
				if get_tile(tile).mine:
					mines += 1
			get_tile(Vector2(x,y)).neighbors = mines




# Get neighbors, ignoring places outside the map
func get_neighbors(origin):
	var x = origin.x
	var y = origin.y
	var neighbors = []
	
	if x > 0:
		#west
		neighbors.append(Vector2(x-1,y))
	if x < MapSize.x-1:
		#east
		neighbors.append(Vector2(x+1,y))
	
	if y > 0:
		# north
		neighbors.append(Vector2(x,y-1))
		if x < MapSize.x-1:
			# northeast
			neighbors.append(Vector2(x+1,y-1))
		if x > 0:
			# northwest
			neighbors.append(Vector2(x-1,y-1))

	if y < MapSize.y-1:
		# south
		neighbors.append(Vector2(x,y+1))
		if x < MapSize.x-1:
			# southeast
			neighbors.append(Vector2(x+1,y+1))
		if x > 0:
			# southwest
			neighbors.append(Vector2(x-1,y+1))

	return neighbors




# get a tile at position x y
func get_tile(pos):
	return MapBox.get_child(pos.x+(pos.y*MapSize.x))




# remove all tiles from the board
func clear_map():
#	for tile in MapBox.get_children():
#		tile.queue_free()
	while MapBox.get_child_count() > 0:
		var node = MapBox.get_child(0)
		MapBox.remove_child(node)
		node.free()


# Called when a tile is clicked as pos
func _on_tile_opened(pos):
	
	# Start the timer if not started yet
	if !is_processing():
		set_process(true)
		
	# increment tile_open count
	tiles_opened += 1
	
	# If we win..
	if !game_over and tiles_opened == MapBox.get_child_count() - MineCount:
		get_node('win').show()
		game_over = true
		set_process(false)
		
		# Highlight all mines in victory green
		for tile in MapBox.get_children():
			if tile.mine:
				tile.set_text("*")
				tile.set('custom_colors/font_color', Color(0,1,0))
	
	# Activate neighbors
	var o = get_tile(pos)
	if o.neighbors == 0 and !o.mine:
		var neighbors = get_neighbors(pos)
		for xy in neighbors:
			if !get_tile(xy).is_pressed():
				get_tile(xy).activate()





# Called when a mine tile is clicked
func _on_hit_mine(hit_mine):
	game_over = true
	get_node('game_over').show()
	for tile in MapBox.get_children():
		if !tile.is_pressed():
			tile.activate()
	set_process(false)



# Process: Count time
func _process(delta):
	Time += delta
	InfoBox.get_node('time/amount').set_text(str(int(Time)))




# Popup newgame dialog
func _on_New_pressed():
	get_node('NewGame').popup_centered()
