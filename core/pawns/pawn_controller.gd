extends Node3D
class_name PawnController

const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")
const AutoCollisionSystem = preload("res://addons/deep_thought/core/pawns/collision/auto_collision_system.gd")

@export var character_body: CharacterBody3D
@export var pawn_visual: PawnVisual
@export var auto_collision_system: AutoCollisionSystem

# Movement settings
@export_group("Movement Settings")
@export var move_speed: float = 5.0
@export var rotation_speed: float = 3.0
@export var jump_force: float = 8.0

# Animation settings
@export_group("Animation Settings")
@export var enable_auto_animations: bool = true
@export var idle_animation: String = "idle"
@export var walk_animation: String = "walk"
@export var run_animation: String = "run"
@export var jump_animation: String = "jump"

# Input settings
@export_group("Input Settings")
@export var input_enabled: bool = true
@export var mouse_look_enabled: bool = true
@export var mouse_sensitivity: float = 0.002

var input_vector: Vector2 = Vector2.ZERO
var velocity: Vector3 = Vector3.ZERO
var is_on_ground: bool = true
var is_moving: bool = false
var is_running: bool = false

func _ready():
	if not character_body:
		Logger.error("PAWN", "❌ CharacterBody3D not assigned to PawnController")
		return
	
	if not pawn_visual:
		Logger.error("PAWN", "❌ PawnVisual not assigned to PawnController")
		return
	
	Logger.info("PAWN", "🎮 Initializing PawnController")
	_setup_input()
	_connect_to_collision_system()

func _setup_input():
	"""Setup input handling"""
	if input_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		Logger.debug("PAWN", "Input system initialized")

func _connect_to_collision_system():
	"""Connect to collision system if available"""
	if auto_collision_system:
		Logger.debug("PAWN", "Connected to AutoCollisionSystem")
		auto_collision_system.connect_to_pawn_visual()

func _input(event):
	if not input_enabled:
		return
	
	_handle_movement_input(event)
	_handle_mouse_input(event)
	_handle_action_input(event)

func _handle_movement_input(event):
	"""Handle movement input"""
	if event.is_action_pressed("move_forward"):
		input_vector.y = -1
	elif event.is_action_released("move_forward"):
		input_vector.y = 0
	
	if event.is_action_pressed("move_backward"):
		input_vector.y = 1
	elif event.is_action_released("move_backward"):
		input_vector.y = 0
	
	if event.is_action_pressed("move_left"):
		input_vector.x = -1
	elif event.is_action_released("move_left"):
		input_vector.x = 0
	
	if event.is_action_pressed("move_right"):
		input_vector.x = 1
	elif event.is_action_released("move_right"):
		input_vector.x = 0

func _handle_mouse_input(event):
	"""Handle mouse input for looking around"""
	if not mouse_look_enabled:
		return
	
	if event is InputEventMouseMotion:
		var rotation_y = -event.relative.x * mouse_sensitivity
		character_body.rotate_y(rotation_y)

func _handle_action_input(event):
	"""Handle action input (jump, run, etc.)"""
	if event.is_action_pressed("jump") and is_on_ground:
		_jump()
	
	if event.is_action_pressed("run"):
		is_running = true
	elif event.is_action_released("run"):
		is_running = false

func _physics_process(delta):
	if not character_body:
		return
	
	_handle_movement(delta)
	_handle_animations()
	_update_collisions()

func _handle_movement(delta):
	"""Handle character movement"""
	var direction = Vector3.ZERO
	
	# Get movement direction
	if input_vector.length() > 0:
		direction = Vector3(input_vector.x, 0, input_vector.y)
		direction = direction.rotated(Vector3.UP, character_body.rotation.y)
		direction = direction.normalized()
	
	# Calculate velocity
	var target_speed = move_speed
	if is_running:
		target_speed *= 1.5
	
	if direction.length() > 0:
		velocity.x = direction.x * target_speed
		velocity.z = direction.z * target_speed
		is_moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, target_speed)
		velocity.z = move_toward(velocity.z, 0, target_speed)
		is_moving = false
	
	# Apply gravity
	if not is_on_ground:
		velocity.y -= 9.8 * delta
	
	# Move character
	character_body.velocity = velocity
	character_body.move_and_slide()
	
	# Update ground state
	is_on_ground = character_body.is_on_floor()

func _handle_animations():
	"""Handle automatic animations based on movement state"""
	if not enable_auto_animations or not pawn_visual:
		return
	
	var animation_to_play = idle_animation
	
	if not is_on_ground:
		animation_to_play = jump_animation
	elif is_moving:
		animation_to_play = run_animation if is_running else walk_animation
	
	# Only change animation if it's different
	var current_anim = pawn_visual.get_current_animation()
	if current_anim != animation_to_play:
		pawn_visual.play_animation(animation_to_play)

func _update_collisions():
	"""Update collision system if available"""
	if auto_collision_system and auto_collision_system.enable_auto_collision:
		# Collision system updates automatically in _process
		pass

func _jump():
	"""Make the character jump"""
	if not is_on_ground:
		return
	
	velocity.y = jump_force
	Logger.debug("PAWN", "Character jumped")

# === Public API ===

func set_movement_enabled(enabled: bool):
	"""Enable or disable movement"""
	input_enabled = enabled
	if not enabled:
		input_vector = Vector2.ZERO
		velocity = Vector3.ZERO
	Logger.debug("PAWN", "Movement " + ("enabled" if enabled else "disabled"))

func set_mouse_look_enabled(enabled: bool):
	"""Enable or disable mouse look"""
	mouse_look_enabled = enabled
	if not enabled:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Logger.debug("PAWN", "Mouse look " + ("enabled" if enabled else "disabled"))

func set_auto_animations_enabled(enabled: bool):
	"""Enable or disable automatic animations"""
	enable_auto_animations = enabled
	Logger.debug("PAWN", "Auto animations " + ("enabled" if enabled else "disabled"))

func play_pose(pose_name: String):
	"""Play a specific pose"""
	if pawn_visual:
		pawn_visual.set_pose(pose_name)
		Logger.debug("PAWN", "Playing pose: " + pose_name)

func set_arm_pose(side: String, pose_name: String):
	"""Set arm pose"""
	if pawn_visual:
		pawn_visual.set_arm_pose(side, pose_name)
		Logger.debug("PAWN", "Set " + side + " arm pose: " + pose_name)

func set_leg_pose(side: String, pose_name: String):
	"""Set leg pose"""
	if pawn_visual:
		pawn_visual.set_leg_pose(side, pose_name)
		Logger.debug("PAWN", "Set " + side + " leg pose: " + pose_name)

func reset_all_poses():
	"""Reset all poses to neutral"""
	if pawn_visual:
		pawn_visual.reset_all_poses()
		Logger.debug("PAWN", "Reset all poses")

func configure_following_system(enable: bool = true, head_intensity: float = 0.3, torso_intensity: float = 0.2, arms_intensity: float = 0.4, legs_intensity: float = 0.3):
	"""Configure the automatic following system"""
	if pawn_visual:
		pawn_visual.configure_following_system(enable, head_intensity, torso_intensity, arms_intensity, legs_intensity)
		Logger.debug("PAWN", "Configured following system")

# === Debug Methods ===

func print_controller_info():
	"""Print controller information"""
	Logger.info("PAWN", "=== PawnController Information ===")
	Logger.info("PAWN", "Input enabled: " + str(input_enabled))
	Logger.info("PAWN", "Mouse look enabled: " + str(mouse_look_enabled))
	Logger.info("PAWN", "Auto animations enabled: " + str(enable_auto_animations))
	Logger.info("PAWN", "Movement speed: " + str(move_speed))
	Logger.info("PAWN", "Is moving: " + str(is_moving))
	Logger.info("PAWN", "Is running: " + str(is_running))
	Logger.info("PAWN", "Is on ground: " + str(is_on_ground))
	Logger.info("PAWN", "Velocity: " + str(velocity))

func get_movement_state() -> Dictionary:
	"""Get current movement state"""
	return {
		"is_moving": is_moving,
		"is_running": is_running,
		"is_on_ground": is_on_ground,
		"velocity": velocity,
		"input_vector": input_vector
	} 
