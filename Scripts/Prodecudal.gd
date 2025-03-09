extends Node
class_name RiverGenerator
# River Generator by dproworldrewrite
# Last updated: 2025-03-09

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
@export var tile_source_id: int = 4
@export var ground_tile: Vector2i = Vector2i(0, 0)
@export var water_tile: Vector2i = Vector2i(1, 0)
@export var bank_tile: Vector2i = Vector2i(2, 0)

# Trash properties
@export_category("Trash Settings")
@export var trash_enabled: bool = true
@export var trash_density: float = 0.1  # Percentage of water tiles that will have trash (0.0 to 1.0)
@export var trash_scale_min: float = 0.8  # Minimum scale for trash objects
@export var trash_scale_max: float = 1.2  # Maximum scale for trash objects
@export var trash_z_index: int = 1  # Z-index for trash sprites
@export var trash_collision_group: String = "trash"  # Collision layer/group for trash objects

# Signals
signal trash_collected(trash_node)

# Internal variables
var trash_container: Node2D
var trash_sprites = []
var trash_objects = []  # Keeps track of created trash objects
var water_cells = []
var trash_collected_count: int = 0
# Trash collection properties
const COLLECTION_COOLDOWN = 0.2  # Seconds between collection checks
var collection_timer: float = 0.0
var trash_count: int = 0
var trash_group: String = "trash"  # Must match the river generator's trash_collision_group
func _ready():
	# Add to group for easy access
	add_to_group("river_generator")
	
	# Initialize trash container
	_setup_trash_container()
	
	# Load trash sprites
	print("Loading trash sprites...")
	_load_trash_sprites()
	
	# Generate the initial river
	print("Generating river on TileMap...")
	generate_river()
	print("River generation complete!")

func _setup_trash_container():
	# Create trash container node if it doesn't exist
	if get_node_or_null("TrashContainer") == null:
		trash_container = Node2D.new()
		trash_container.name = "TrashContainer"
		add_child(trash_container)
	else:
		trash_container = get_node("TrashContainer")
	
	print("Trash container setup complete")

func _load_trash_sprites():
	# Load all trash sprites from res://Assets/Trash/
	for i in range(16):  # From sprite_00.png to sprite_15.png
		var sprite_path = "res://Assets/Trash/sprite_%02d.png" % i
		var texture = load(sprite_path)
		if texture:
			trash_sprites.append(texture)
		else:
			push_error("Failed to load sprite: " + sprite_path)
	
	print("Loaded ", trash_sprites.size(), " trash sprites")

# Generates a new river
func generate_river():
	if not tilemap:
		push_error("TileMap not assigned!")
		return

	# Clear existing trash objects
	clear_trash_objects()

	# Reset trash count
	trash_collected_count = 0

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
	water_cells.clear()
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
	
	# Place trash in the water if enabled
	if trash_enabled and water_cells.size() > 0:
		place_trash()

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

# Places trash objects in water
# Places trash objects in water
func place_trash():
	if trash_sprites.size() == 0:
		push_error("No trash sprites loaded!")
		return
	
	# Make sure trash container exists
	if !is_instance_valid(trash_container):
		_setup_trash_container()
	
	# Shuffle water cells for random distribution
	var shuffled_cells = water_cells.duplicate()
	shuffled_cells.shuffle()
	
	# Determine how many trash objects to place
	var trash_count = int(water_cells.size() * trash_density)
	print("Placing ", trash_count, " trash objects in water...")
	
	for i in range(trash_count):
		if i >= shuffled_cells.size():
			break
			
		var water_pos = shuffled_cells[i]
		
		# Create a trash object (Area2D for collision detection)
		var trash_object = Area2D.new()
		trash_object.position = tilemap.map_to_local(water_pos)
		trash_object.collision_layer = 2  # Set to layer 2 (2^1)
		trash_object.collision_mask = 0   # Won't detect anything itself
		trash_object.set_meta("is_trash", true)
		
		# Add to collision group
		trash_object.add_to_group(trash_collision_group)
		
		# Create sprite
		var trash_sprite = Sprite2D.new()
		trash_sprite.texture = trash_sprites[randi() % trash_sprites.size()]
		
		# Randomize rotation and scale
		trash_object.rotation = randf() * TAU  # Random rotation (0 to 2π)
		var scale_factor = randf_range(trash_scale_min, trash_scale_max)
		trash_object.scale = Vector2(scale_factor, scale_factor)
		
		# Add some random offset within the tile
		var tile_size = tilemap.cell_quadrant_size
		trash_object.position += Vector2(
			randf_range(-tile_size / 4, tile_size / 4),
			randf_range(-tile_size / 4, tile_size / 4)
		)
		
		# Set z-index to ensure trash appears above water
		trash_sprite.z_index = trash_z_index
		
		# Create collision shape
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = trash_sprite.texture.get_width() * scale_factor * 0.3  # Smaller than the actual sprite
		collision.shape = shape
		
		# Add sprite and collision to the trash object
		trash_object.add_child(trash_sprite)
		trash_object.add_child(collision)
		
		# Add to the scene
		trash_container.add_child(trash_object)
		trash_objects.append(trash_object)
	
	print("Placed ", trash_objects.size(), " trash objects")

# Handle trash collection
func collect_trash(trash_node):
	# Ensure we don't double-collect
	if trash_node.has_meta("collected") and trash_node.get_meta("collected"):
		return
		
	# Mark as collected to prevent multiple collections
	trash_node.set_meta("collected", true)
	
	# Increase the counter
	trash_count += 1
	
	# Emit signal with updated count
	emit_signal("trash_collected", trash_count)
	
	# Optional feedback
	print("Boat collected trash! Total: ", trash_count)
	
	# Get river generator reference if needed
	var river_generators = get_tree().get_nodes_in_group("river_generator")
	if river_generators.size() > 0:
		river_generators[0].collect_trash(trash_node)
	else:
		# If river generator not found, remove the trash directly
		trash_node.queue_free()

# Clear all trash objects
func clear_trash_objects():
	for obj in trash_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	trash_objects.clear()

# Regenerate the river with a new seed when "R" is pressed
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		print("Regenerating river...")
		regenerate(randi())

func regenerate(new_seed: int):
	seed_value = new_seed
	generate_river()

# Public method to toggle trash visibility
func toggle_trash(enabled: bool):
	trash_enabled = enabled
	if enabled:
		if water_cells.size() > 0:
			place_trash()
	else:
		clear_trash_objects()
		
# Get the current trash count
func get_trash_collected_count() -> int:
	return trash_collected_count


func _on_trash_collector_area_entered(area: Area2D) -> void:
	print("test")
	if area.is_in_group("trash") and collection_timer <= 0:
		collect_trash(area)
		collection_timer = COLLECTION_COOLDOWN
		
# New function to handle trash removal
func remove_trash(trash_node):
	# Remove from our tracking array
	if trash_objects.has(trash_node):
		trash_objects.erase(trash_node)
	
	# Increment collection counter
	trash_collected_count += 1
	global.trash += 1
	var t_label = $"new-boat"/Camera2D/CanvasLayer/Trash
	t_label.text = "Trash: " + str(global.trash)
	
	# Queue for deletion
	trash_node.queue_free()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")
