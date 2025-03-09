extends CharacterBody2D

# Base multipliers for boat physics
const BASE_SPEED = 100.0
const MAX_TURN_RATE = 0.8
const STEERING_RESPONSE = 0.7
const TURN_DAMPING = 1.2

# Rowing configuration
const POWER_STROKE_DURATION = 10.0  # Seconds a power stroke lasts
const FATIGUE_RECOVERY_RATE = 5.0   # Points of endurance recovered per second
const FATIGUE_BUILDUP_RATE = 2.0    # Base fatigue increase rate during power strokes
const CRAB_CHECK_INTERVAL = 0.5     # How often to check for crabs (seconds)
const CRAB_DURATION = 2.0           # How long a crab affects performance (seconds)
const CRAB_SPEED_PENALTY = 0.3      # Speed multiplier reduction when catching a crab
const CRAB_STEERING_EFFECT = 1.2    # How much a crab affects steering

# Animation parameters
@export var normal_row_speed: float = 10.0
@export var power_stroke_row_speed: float = 15.0
@export var tired_row_speed: float = 7.0
@export var crabbed_animation_speed: float = 5.0
@export var synchronized_rowing: bool = false
@export var max_offset: float = 0.5

# Rower setup - even positions are port (left), odd are starboard (right)
var rowers = {
	# Port side (left)
	0: {
		"name": "Alex 8",
		"strength": 85,  # Power house
		"endurance": 60,
		"technique": 0.7,
		"fatigue": 0,    # Current fatigue level
		"crabbed": false, # Whether this rower currently has a crab
		"side": "port",
		"sprite": null   # Will store reference to AnimatedSprite2D
	},
	2: {
		"name": "Morgan 6",
		"strength": 75,
		"endurance": 80,  # Good stamina
		"technique": 0.85,
		"fatigue": 0,
		"crabbed": false,
		"side": "port",
		"sprite": null
	},
	4: {
		"name": "Jamie 4",
		"strength": 90,  # Strongest
		"endurance": 65,
		"technique": 0.75,
		"fatigue": 0,
		"crabbed": false,
		"side": "port",
		"sprite": null
	},
	6: {
		"name": "Taylor 2",
		"strength": 70,
		"endurance": 75,
		"technique": 0.9,  # Good technique
		"fatigue": 0,
		"crabbed": false,
		"side": "port",
		"sprite": null
	},
	# Starboard side (right)
	1: {
		"name": "Jordan 7",
		"strength": 80,
		"endurance": 70,
		"technique": 0.8,
		"fatigue": 0,
		"crabbed": false,
		"side": "starboard",
		"sprite": null
	},
	3: {
		"name": "Casey 5",
		"strength": 65,
		"endurance": 95,  # Endurance specialist
		"technique": 0.85,
		"fatigue": 0,
		"crabbed": false,
		"side": "starboard",
		"sprite": null
	},
	5: {
		"name": "Riley 3",
		"strength": 60,
		"endurance": 85,
		"technique": 0.95,  # Best technique
		"fatigue": 0,
		"crabbed": false,
		"side": "starboard",
		"sprite": null
	},
	7: {
		"name": "Avery 1",
		"strength": 75,
		"endurance": 75,  # Balanced
		"technique": 0.65,  # Worst technique
		"fatigue": 0,
		"crabbed": false,
		"side": "starboard",
		"sprite": null
	}
}

# Boat state
var current_turn_rate = 0.0
var power_stroke_active = false
var power_stroke_timer = 0.0
var crab_check_timer = 0.0
var port_side_efficiency = 1.0
var starboard_side_efficiency = 1.0

func _ready():
	# Connect sprite references with rower data
	var sprite_container = $AnimatedSprite2D
	var sprite_nodes = []
	
	# Get all rower sprite nodes
	if sprite_container is AnimatedSprite2D:
		sprite_nodes.append(sprite_container)
	
	for child in sprite_container.get_children():
		if child is AnimatedSprite2D:
			sprite_nodes.append(child)
	
	# Assign sprite references to rower data
	# This assumes the order of sprite nodes matches the rower positions
	# Adjust the logic if your node order is different
	var i = 0
	for position in rowers:
		if i < sprite_nodes.size():
			rowers[position].sprite = sprite_nodes[i]
			i += 1
	
	# Start rowing animations
	start_rowing()

func _physics_process(delta: float) -> void:
	# Handle power stroke input
	if Input.is_action_just_pressed("power_stroke"):  # You'll need to define this action
		power_stroke_active = true
		power_stroke_timer = POWER_STROKE_DURATION
		update_animation_speeds()
	
	# Update power stroke timer
	if power_stroke_active:
		power_stroke_timer -= delta
		if power_stroke_timer <= 0:
			power_stroke_active = false
			update_animation_speeds()
	
	# Update rower fatigue and check for crabs
	update_rower_states(delta)
	
	# Calculate contributions and boat physics
	var boat_speed = calculate_boat_speed()
	handle_steering(delta)
	
	# Set velocity along the boat's forward direction
	velocity = Vector2(boat_speed, 0).rotated(rotation)
	move_and_slide()

func update_rower_states(delta: float) -> void:
	# Check for crabs periodically
	crab_check_timer -= delta
	if crab_check_timer <= 0:
		crab_check_timer = CRAB_CHECK_INTERVAL
		check_for_crabs()
	
	# Reset side efficiencies
	port_side_efficiency = 1.0
	starboard_side_efficiency = 1.0
	
	# Update each rower's state
	var animation_update_needed = false
	
	for position in rowers:
		var rower = rowers[position]
		var old_fatigue = rower.fatigue
		var old_crabbed = rower.crabbed
		
		# Update fatigue based on activity
		if power_stroke_active:
			# During power stroke, fatigue increases based on inverse of endurance
			rower.fatigue += FATIGUE_BUILDUP_RATE * (100.0 - rower.endurance) / 100.0 * delta
			rower.fatigue = min(rower.fatigue, 100.0)  # Cap at 100
		else:
			# Recovery during normal rowing
			rower.fatigue -= FATIGUE_RECOVERY_RATE * delta
			rower.fatigue = max(rower.fatigue, 0.0)  # Minimum 0
		
		# If rower has a crab, reduce their side's efficiency
		if rower.crabbed:
			if rower.side == "port":
				port_side_efficiency -= CRAB_SPEED_PENALTY
			else:
				starboard_side_efficiency -= CRAB_SPEED_PENALTY
		
		# Check if animation update needed
		if (abs(old_fatigue - rower.fatigue) > 10.0) or (old_crabbed != rower.crabbed):
			animation_update_needed = true
	
	# Update animations if needed
	if animation_update_needed:
		update_animation_speeds()

func check_for_crabs() -> void:
	var animation_update_needed = false
	
	for position in rowers:
		var rower = rowers[position]
		
		# Skip if already has a crab
		if rower.crabbed:
			continue
		
		# Calculate crab chance: higher with lower technique, higher fatigue
		var crab_chance = (1.0 - rower.technique) * (1.0 + rower.fatigue / 100.0) * 0.05
		
		# Roll for crab
		if randf() < crab_chance:
			rower.crabbed = true
			animation_update_needed = true
			
			# Create a timer to clear the crab after duration
			var timer = get_tree().create_timer(CRAB_DURATION)
			timer.connect("timeout", Callable(self, "_on_crab_timeout").bind(position))
			
			# Visual/audio feedback could be added here
			print(rower.name + " caught a crab!")
	
	if animation_update_needed:
		update_animation_speeds()

func _on_crab_timeout(position: int) -> void:
	if position in rowers:
		rowers[position].crabbed = false
		update_animation_speeds()

func calculate_boat_speed() -> float:
	var port_contribution = 0.0
	var starboard_contribution = 0.0
	var total_rowers = 0
	
	for position in rowers:
		var rower = rowers[position]
		total_rowers += 1
		
		# Calculate effective strength based on endurance and fatigue
		var effective_strength = rower.strength * (1.0 - rower.fatigue / 200.0)  # Fatigue has half effect
		
		# Apply power stroke boost if active
		if power_stroke_active:
			# Endurance affects how much benefit they get from power stroke
			var power_boost = 1.0 + (rower.endurance / 100.0) * 0.5
			effective_strength *= power_boost
		
		# Add to the appropriate side
		if rower.side == "port":
			port_contribution += effective_strength * port_side_efficiency
		else:
			starboard_contribution += effective_strength * starboard_side_efficiency
	
	# Average the contributions and apply base speed
	var average_contribution = (port_contribution + starboard_contribution) / total_rowers
	return average_contribution * BASE_SPEED / 50.0  # Divide by 50 to normalize (stats go up to 100)

func handle_steering(delta: float) -> void:
	# Basic steering input
	var steering_input = 0.0
	if Input.is_action_pressed("ui_up"):
		steering_input = -1.0  # Counter-clockwise
	elif Input.is_action_pressed("ui_down"):
		steering_input = 1.0   # Clockwise
	
	# Apply side imbalance to steering (if one side is less efficient due to crabs)
	var side_imbalance = (port_side_efficiency - starboard_side_efficiency) * CRAB_STEERING_EFFECT
	steering_input += side_imbalance
	
	# Apply steering forces with lag
	var target_turn_rate = steering_input * MAX_TURN_RATE
	current_turn_rate = lerp(current_turn_rate, target_turn_rate, STEERING_RESPONSE * delta)
	
	# Apply natural damping
	if abs(steering_input) < 0.1:
		current_turn_rate = lerp(current_turn_rate, 0.0, TURN_DAMPING * delta)
	
	# Apply turn
	rotation += current_turn_rate * delta

# Animation functions integrated from the original animation script

func start_rowing():
	if synchronized_rowing:
		# Start all rowers in sync
		for position in rowers:
			var rower = rowers[position]
			if rower.sprite:
				rower.sprite.play("row")
	else:
		# Start with random offsets for more natural look
		for position in rowers:
			var rower = rowers[position]
			if rower.sprite:
				var offset = randf() * max_offset
				await get_tree().create_timer(offset).timeout
				rower.sprite.play("row")
	
	# Initialize animation speeds based on initial state
	update_animation_speeds()

func stop_rowing():
	for position in rowers:
		var rower = rowers[position]
		if rower.sprite:
			rower.sprite.stop()

func update_animation_speeds():
	for position in rowers:
		var rower = rowers[position]
		if not rower.sprite:
			continue
		
		var speed = normal_row_speed
		
		# Adjust speed based on rower state
		if rower.crabbed:
			# Crabbed animation is very slow and jerky
			speed = crabbed_animation_speed
		elif power_stroke_active:
			# Power stroke is faster than normal rowing
			speed = power_stroke_row_speed - (rower.fatigue / 100.0 * 5.0)  # Fatigue reduces speed
		else:
			# Normal rowing affected by fatigue
			speed = normal_row_speed - (rower.fatigue / 100.0 * 3.0)
			
			# Ensure animation doesn't get too slow
			if speed < tired_row_speed:
				speed = tired_row_speed
		
		rower.sprite.speed_scale = speed / 10.0
