extends Node

@export var tilemap: TileMap  # Reference to the TileMap
@export var layer: int = 0  # TileMap layer index
@export var map_width: int = 50
@export var map_height: int = 50
@export var seed_value: int = 0  # Random seed for river variation
@export var start_offset: int = 64  # Number of tiles before origin to start generation

# River properties
@export var river_width_min: int = 2
@export var river_width_max: int = 5
@export var river_curve_intensity: float = 0.1  # Controls river bending

# Tile atlas coordinates (from TileSet)
@export var tile_source_id: int = 0
@export var ground_tile: Vector2i = Vector2i(0, 0)
@export var water_tile: Vector2i = Vector2i(1, 0)
@export var bank_tile: Vector2i = Vector2i(2, 0)

func _ready():
	print("Generating river on TileMap...")
	generate_river()
	print("River generation complete!")

# Generates a new river
func generate_river():
	if not tilemap:
		push_error("TileMap not assigned!")
		return

	# Clear the tilemap layer
	tilemap.clear_layer(layer)

	# Calculate map boundaries
	var start_x = -start_offset
	var end_x = map_width - start_offset
	var half_height = map_height / 2
	
	# Fill the entire map with ground tiles
	for y in range(-half_height, half_height):
		for x in range(start_x, end_x):
			tilemap.set_cell(layer, Vector2i(x, y), tile_source_id, ground_tile)

	# Generate river path
	var river_path = []
	var river_widths = []

	var noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.1

	# River flows along y=0 with some noise-based variation
	var center_y = 0 
	
	for x in range(start_x, end_x):
		# Apply noise-based movement to vary the river's y-position
		var noise_value = noise.get_noise_2d(x * river_curve_intensity, 0) * (half_height * 0.5)
		var pos_y = center_y + int(noise_value)
		pos_y = clamp(pos_y, -half_height + river_width_max, half_height - river_width_max)

		# Generate river width with variation
		var width_noise = noise.get_noise_2d(x * 0.2, 1000)
		var river_width = int(lerp(river_width_min, river_width_max, (width_noise + 1) / 2))

		river_path.append(Vector2i(x, pos_y))
		river_widths.append(river_width)

	print("River path size: ", river_path.size())

	# Place water tiles
	var water_cells = []
	for i in range(river_path.size()):
		var center = river_path[i]
		var width = river_widths[i]

		for y in range(center.y - width, center.y + width + 1):
			if y >= -half_height and y < half_height:
				tilemap.set_cell(layer, Vector2i(center.x, y), tile_source_id, water_tile)
				water_cells.append(Vector2i(center.x, y))

	print("Placed ", water_cells.size(), " water tiles")

	# Place riverbanks
	place_river_banks(water_cells, start_x, end_x, half_height)

# Places riverbank tiles adjacent to water
func place_river_banks(water_cells: Array, start_x: int, end_x: int, half_height: int):
	var directions = [
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0)    # Right
	]

	var bank_count = 0
	for water_pos in water_cells:
		for dir in directions:
			var neighbor_pos = water_pos + dir
			if neighbor_pos.x < start_x or neighbor_pos.x >= end_x or neighbor_pos.y < -half_height or neighbor_pos.y >= half_height:
				continue

			# If neighbor is ground, replace it with a bank tile
			var source_id = tilemap.get_cell_source_id(layer, neighbor_pos)
			var atlas_coords = tilemap.get_cell_atlas_coords(layer, neighbor_pos)

			if source_id == tile_source_id and atlas_coords == ground_tile:
				tilemap.set_cell(layer, neighbor_pos, tile_source_id, bank_tile)
				bank_count += 1

	print("Placed ", bank_count, " bank tiles")

# Regenerate the river with a new seed when "R" is pressed
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		print("Regenerating river...")
		regenerate(randi())

func regenerate(new_seed: int):
	seed_value = new_seed
	generate_river()
