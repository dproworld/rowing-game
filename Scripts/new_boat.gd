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
@export_range(0.0, 2.0) var speed_variance: float = 0.3  # Variance in speed multiplier during stroke cycle
@export_range(0.0, 1.0) var collective_fatigue_impact: float = 0.5  # How much team fatigue affects overall boat speed

# Rowing stroke phases
@export_range(0, 12) var drive_phase_start: int = 2  # Frame where drive phase starts
@export_range(0, 12) var drive_phase_end: int = 6    # Frame where drive phase ends

# Set synchronized rowing to true by default as requested
var synchronized_rowing: bool = true
var max_offset: float = 0.5
var current_animation_frame: int = 0  # Track current animation frame for synchronized movement
var team_fatigue: float = 0.0         # Average fatigue level for the whole team

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
var animation_frame_changed: bool = false
var team_animation_sync_timer: float = 0.0
var crab_recovery_state: bool = false
var crab_recovery_timer: float = 0.0
var crab_recovery_duration: float = 2.5  # How long the boat pauses after a crab
var boat_momentum: float = 0.0
var drag_coefficient: float = 0.05  # How quickly boat loses speed during normal rowing
var crab_drag_coefficient: float = 0.6  # Much higher drag during crab recovery
var momentum_retention: float = 0.96  # Higher value for better gliding (96% retention)
var crab_steering_impulse: float = 0.0  # Direction and magnitude of steering due to crab
var crab_impulse_decay: float = 0.8     # How quickly crab steering effect decays per second
const CRAB_STEERING_IMPULSE_STRENGTH = 0.3  # Base steering impulse multiplier from a crab
const CRAB_STEERING_MIN = 0.1  # Minimum steering effect even at very low speeds

func _ready():
	# Find the AnimatedSprite2D nodes using more reliable methods
	var sprite_nodes = []

	# First try direct child access
	var animated_sprite_parent = find_child("AnimatedSprite2D", true, false)

	# If that fails, try finding it within BoatTemplate
	if animated_sprite_parent == null:
		var boat_template = find_child("BoatTemplate", true, false)
		if boat_template != null:
			animated_sprite_parent = boat_template.find_child("AnimatedSprite2D", true, false)

	if animated_sprite_parent == null:
		push_error("Could not find AnimatedSprite2D container. Check your node structure.")
		print_debug("Available children in root: ", get_children())
		return
	else:
		print("Found AnimatedSprite2D container: ", animated_sprite_parent.name)

	# Add the container itself if it's an AnimatedSprite2D
	if animated_sprite_parent is AnimatedSprite2D:
		sprite_nodes.append(animated_sprite_parent)

	# Get all children that are AnimatedSprite2D nodes
	for child in animated_sprite_parent.get_children():
		if child is AnimatedSprite2D:
			sprite_nodes.append(child)
			print("Found rower sprite: ", child.name)

	print("Found " + str(sprite_nodes.size()) + " rower sprites")

	# Assign sprite references to rower data
	var i = 0
	for seat_pos in rowers:
		if i < sprite_nodes.size():
			rowers[seat_pos].sprite = sprite_nodes[i]

			# Connect frame change signal for the first rower to track animation state
			if i == 0 and sprite_nodes[i].sprite_frames != null:
				sprite_nodes[i].animation_finished.connect(_on_animation_finished)
				sprite_nodes[i].frame_changed.connect(_on_frame_changed.bind(sprite_nodes[i]))

			print("Assigned " + sprite_nodes[i].name + " to position " + str(seat_pos) + " (" + rowers[seat_pos].name + ")")
			i += 1

	# Start rowing animations
	start_rowing()

func _physics_process(delta: float) -> void:
	# Handle crab recovery state
	if crab_recovery_state:
		crab_recovery_timer -= delta
		if crab_recovery_timer <= 0:
			restart_after_crab()

		# Apply crab steering impulse during recovery
		if abs(crab_steering_impulse) > 0.001:
			# Make the steering effect proportional to current speed
			var current_speed = boat_momentum / BASE_SPEED
			var speed_adjusted_impulse = crab_steering_impulse * current_speed

			# Apply the steering impulse to the boat's rotation
			rotation += speed_adjusted_impulse * delta

			# Gradually reduce the impulse over time
			crab_steering_impulse *= (1.0 - crab_impulse_decay * delta)

		# Allow coxswain to steer even during crab recovery
		handle_steering(delta)

		# Let boat glide to a stop with much higher drag during crab recovery
		boat_momentum = max(0, boat_momentum - crab_drag_coefficient * delta * boat_momentum)
		velocity = Vector2(boat_momentum, 0).rotated(rotation)
		move_and_slide()
		return

	# Handle power stroke input - using ui_accept instead of custom power_stroke action
	if Input.is_action_just_pressed("ui_accept"):
		power_stroke_active = true
		power_stroke_timer = POWER_STROKE_DURATION
		update_animation_speeds()
		print("Power stroke activated!")

	# Update power stroke timer
	if power_stroke_active:
		power_stroke_timer -= delta
		if power_stroke_timer <= 0:
			power_stroke_active = false
			update_animation_speeds()
			print("Power stroke ended")

	# Update rower fatigue and check for crabs
	update_rower_states(delta)

	# Calculate contributions and boat physics
	var boat_speed = calculate_boat_speed()
	handle_steering(delta)

	# Update momentum with a blend between current momentum and new speed
	# This creates smooth transitions between power and recovery phases
	boat_momentum = boat_momentum * momentum_retention + boat_speed * (1.0 - momentum_retention)

	# Apply water resistance/drag - make it proportional to boat speed for more realistic drag
	# This creates a more natural gliding effect that slows down more gradually
	boat_momentum = max(0, boat_momentum - drag_coefficient * delta * boat_momentum)

	# Set velocity along the boat's forward direction using momentum
	velocity = Vector2(boat_momentum, 0).rotated(rotation)
	move_and_slide()

# Track animation frame changes to synchronize boat speed with rowing
func _on_frame_changed(sprite: AnimatedSprite2D) -> void:
	current_animation_frame = sprite.frame
	animation_frame_changed = true

func _on_animation_finished() -> void:
	# Animation looped back to start
	current_animation_frame = 0

func update_rower_states(delta: float) -> void:
	# Check for crabs periodically
	crab_check_timer -= delta
	if crab_check_timer <= 0:
		crab_check_timer = CRAB_CHECK_INTERVAL
		check_for_crabs()

	# Reset side efficiencies
	port_side_efficiency = 1.0
	starboard_side_efficiency = 1.0

	# Update each rower's state and calculate team fatigue
	var animation_update_needed = false
	var total_fatigue = 0.0

	for seat_pos in rowers:
		var rower = rowers[seat_pos]
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

		total_fatigue += rower.fatigue

		# If rower has a crab, reduce their side's efficiency
		if rower.crabbed:
			if rower.side == "port":
				port_side_efficiency -= CRAB_SPEED_PENALTY
			else:
				starboard_side_efficiency -= CRAB_SPEED_PENALTY

		# Check if animation update needed
		if (abs(old_fatigue - rower.fatigue) > 10.0) or (old_crabbed != rower.crabbed):
			animation_update_needed = true

	# Calculate team fatigue average
	team_fatigue = total_fatigue / max(rowers.size(), 1)

	# Update animations if needed
	if animation_update_needed:
		update_animation_speeds()

func check_for_crabs() -> void:
	var animation_update_needed = false
	var crab_occurred = false
	var crab_side = ""

	for seat_pos in rowers:
		var rower = rowers[seat_pos]

		# Skip if already has a crab
		if rower.crabbed:
			continue

		# Calculate crab chance: higher with lower technique, higher fatigue, but much less frequent overall
		var crab_chance = (1.0 - rower.technique) * (1.0 + rower.fatigue / 100.0) * 0.00001

		# Roll for crab
		if randf() < crab_chance and not crab_recovery_state:  # Only check for crabs if not already in recovery
			rower.crabbed = true
			animation_update_needed = true
			crab_occurred = true
			crab_side = rower.side

			# Create a timer to clear the crab after duration
			var timer = get_tree().create_timer(CRAB_DURATION)
			timer.connect("timeout", Callable(self, "_on_crab_timeout").bind(seat_pos))

			# Stop the boat when a crab occurs
			stop_boat_for_crab(crab_side)

			# Visual/audio feedback could be added here
			print(rower.name + " caught a crab on the " + crab_side + " side!")

			# Only process one crab at a time (first one found)
			break

func _on_crab_timeout(seat_pos: int) -> void:
	if seat_pos in rowers:
		rowers[seat_pos].crabbed = false
		update_animation_speeds()
		# Note: We don't restart the boat here anymore, as that's handled by the crab_recovery_timer

# Called when a rower catches a crab to stop the boat
func stop_boat_for_crab(crab_side: String = "") -> void:
	if not crab_recovery_state:  # Avoid triggering multiple times
		crab_recovery_state = true
		crab_recovery_timer = crab_recovery_duration

		# Calculate speed-dependent steering impulse
		# At low speeds, the effect is small but still present
		var speed_factor = clamp(boat_momentum / BASE_SPEED, CRAB_STEERING_MIN, 1.0)
		var impulse_strength = CRAB_STEERING_IMPULSE_STRENGTH * speed_factor

		# Apply steering impulse based on which side caught the crab
		if crab_side == "port":
			# Port side crab makes the boat veer to the left (negative value)
			crab_steering_impulse = -impulse_strength
			print("Crab on port side! Boat veering to port... (Impulse: " + str(crab_steering_impulse) + ")")
		elif crab_side == "starboard":
			# Starboard side crab makes the boat veer to the right (positive value)
			crab_steering_impulse = impulse_strength
			print("Crab on starboard side! Boat veering to starboard... (Impulse: " + str(crab_steering_impulse) + ")")

		# Keep boat's current momentum but stop rowing
		# Set all rowers to frame 9
		for seat_pos in rowers:
			var rower = rowers[seat_pos]
			if rower.sprite:
				rower.sprite.stop()
				rower.sprite.frame = 9  # Set to specific recovery position

		print("Crab caught! Boat gliding to a stop...")

# Restart boat and animations after recovering from a crab
func restart_after_crab() -> void:
	crab_recovery_state = false
	boat_momentum = 0  # Start with zero momentum when restarting
	crab_steering_impulse = 0  # Reset any remaining steering impulse

	# Clear all remaining crabs
	for seat_pos in rowers:
		var rower = rowers[seat_pos]
		rower.crabbed = false

	# Restart all rowers in sync
	start_rowing()
	update_animation_speeds()
	print("Boat restarting after crab recovery")

func calculate_boat_speed() -> float:
	var port_contribution = 0.0
	var starboard_contribution = 0.0
	var total_rowers = 0

	for seat_pos in rowers:
		var rower = rowers[seat_pos]
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
	var average_contribution = (port_contribution + starboard_contribution) / max(total_rowers, 1)

	# Calculate base boat speed
	var base_boat_speed = average_contribution * BASE_SPEED / 50.0

	# Apply speed variance based on stroke phase
	var stroke_phase_multiplier = get_stroke_phase_multiplier()

	# Apply collective fatigue penalty to overall boat speed
	var fatigue_multiplier = 1.0 - (team_fatigue / 100.0 * collective_fatigue_impact)

	# Final boat speed calculation
	return base_boat_speed * stroke_phase_multiplier * fatigue_multiplier

# Calculate a speed multiplier based on the current rowing stroke phase
func get_stroke_phase_multiplier() -> float:
	# Determine where we are in the stroke cycle
	var is_in_drive_phase = (current_animation_frame >= drive_phase_start and
							current_animation_frame <= drive_phase_end)

	# During drive phase, boat moves faster
	if is_in_drive_phase:
		return 1.0 + speed_variance
	else:
		# Recovery phase should add minimal additional power
		# The boat will maintain momentum through the momentum_retention system
		return 0.2  # Small contribution during recovery phase

func handle_steering(delta: float) -> void:
	# Basic steering input

	var steering_input = 0.0


	# Apply side imbalance to steering (if one side is less efficient due to crabs)
	var side_imbalance = (port_side_efficiency - starboard_side_efficiency) * CRAB_STEERING_EFFECT
	steering_input += side_imbalance

	# Calculate speed-based steering effectiveness
	# A stationary boat (0 momentum) has almost no steering ability
	# As speed increases, steering becomes more effective
	var speed_factor = clamp(boat_momentum / (BASE_SPEED * 0.8), 0.05, 1.0)

	# Get scaling factor for steering effectiveness based on boat state
	var steering_power_factor = 1.0
	if crab_recovery_state:
		# Steering is less effective but still works during crab recovery
		steering_power_factor = 0.5

	# Apply steering forces with lag - now scaled by boat speed
	var target_turn_rate = steering_input * MAX_TURN_RATE * steering_power_factor * speed_factor
	current_turn_rate = lerp(current_turn_rate, target_turn_rate, STEERING_RESPONSE * delta)

	# Apply natural damping
	if abs(steering_input) < 0.1:
		current_turn_rate = lerp(current_turn_rate, 0.0, TURN_DAMPING * delta)

	# Apply turn
	rotation += current_turn_rate * delta
# Animation functions integrated from the original animation script

func start_rowing():
	print("Starting rowing animations...")

	# Synchronized rowing is now true by default as requested
	# Start all rowers in sync
	for seat_pos in rowers:
		var rower = rowers[seat_pos]
		if rower.sprite:
			if rower.sprite.sprite_frames != null and rower.sprite.sprite_frames.has_animation("row"):
				rower.sprite.play("row")
				print(rower.name + " started synchronized rowing")
			else:
				push_error("Rower " + rower.name + " missing 'row' animation")

	# Initialize animation speeds based on initial state
	update_animation_speeds()

func stop_rowing():
	for seat_pos in rowers:
		var rower = rowers[seat_pos]
		if rower.sprite:
			rower.sprite.stop()

func update_animation_speeds():
	# Calculate base animation speed based on team fatigue
	var team_animation_speed = normal_row_speed * (1.0 - (team_fatigue / 100.0 * 0.3))

	# Apply minimum speed limit
	if team_animation_speed < tired_row_speed:
		team_animation_speed = tired_row_speed

	# Adjust for power stroke
	if power_stroke_active:
		team_animation_speed = power_stroke_row_speed * (1.0 - (team_fatigue / 100.0 * 0.3))

	for seat_pos in rowers:
		var rower = rowers[seat_pos]
		if not rower.sprite:
			continue

		var speed = team_animation_speed

		# Crabbed rowers have individual slowdown
		if rower.crabbed:
			speed = crabbed_animation_speed

		rower.sprite.speed_scale = speed / 10.0
