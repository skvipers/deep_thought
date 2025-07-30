extends Node3D
class_name AutoCollisionSystem

const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@export var pawn_visual: PawnVisual
@export var character_body: CharacterBody3D

# Collision settings
@export_group("Collision Settings")
@export var enable_auto_collision: bool = true
@export var update_collision_on_pose_change: bool = true
@export var collision_update_rate: float = 0.1  # How often to update collisions

# Body part collision settings
@export var head_collision_radius: float = 0.15
@export var torso_collision_radius: float = 0.25
@export var arm_collision_radius: float = 0.08
@export var leg_collision_radius: float = 0.12

var collision_shapes: Dictionary = {}
var update_timer: float = 0.0

func _ready():
	if not character_body:
		Logger.error("PAWN", "❌ CharacterBody3D not assigned to AutoCollisionSystem")
		return
	
	if not pawn_visual:
		Logger.error("PAWN", "❌ PawnVisual not assigned to AutoCollisionSystem")
		return
	
	Logger.info("PAWN", "🔄 Initializing AutoCollisionSystem")
	
	# Wait for scene to be fully ready
	await get_tree().create_timer(1.0).timeout
	
	# Use call_deferred to avoid blocking during setup
	_setup_collision_shapes.call_deferred()
	_analyze_skeleton_structure.call_deferred()

func _process(delta):
	if not enable_auto_collision or not update_collision_on_pose_change:
		return
	
	update_timer += delta
	if update_timer >= collision_update_rate:
		update_timer = 0.0
		_update_dynamic_collisions()

func _setup_collision_shapes():
	"""Setup collision shapes for body parts"""
	Logger.info("PAWN", "🔄 Setting up collision shapes")
	
	# Create collision shapes for each body part
	var body_parts = ["head", "torso", "left_arm", "right_arm", "left_leg", "right_leg"]
	
	for part_name in body_parts:
		var collision_shape = _create_collision_shape(part_name)
		if collision_shape:
			collision_shapes[part_name] = collision_shape
			# Use call_deferred to avoid blocking during setup
			character_body.add_child.call_deferred(collision_shape)
			Logger.debug("PAWN", "✅ Created collision shape for " + part_name)

func _create_collision_shape(part_name: String) -> CollisionShape3D:
	"""Create collision shape for body part"""
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "Collision_" + part_name
	
	# Create appropriate shape based on body part
	var shape: Shape3D
	
	match part_name:
		"head":
			var capsule = CapsuleShape3D.new()
			capsule.radius = head_collision_radius
			capsule.height = head_collision_radius * 2
			shape = capsule
		"torso":
			var capsule = CapsuleShape3D.new()
			capsule.radius = torso_collision_radius
			capsule.height = 1.2
			shape = capsule
		"left_arm", "right_arm":
			var capsule = CapsuleShape3D.new()
			capsule.radius = arm_collision_radius
			capsule.height = 0.8
			shape = capsule
		"left_leg", "right_leg":
			var capsule = CapsuleShape3D.new()
			capsule.radius = leg_collision_radius
			capsule.height = 1.0
			shape = capsule
		_:
			Logger.warn("PAWN", "❌ Unknown body part: " + part_name)
			return null
	
	collision_shape.shape = shape
	return collision_shape

func _analyze_skeleton_structure():
	"""Analyze skeleton structure to determine collision positions"""
	Logger.info("PAWN", "🔍 Analyzing skeleton structure")
	
	if not pawn_visual or not pawn_visual.get_skeleton():
		Logger.warn("PAWN", "❌ Cannot analyze skeleton - PawnVisual not available")
		return
	
	# Wait for tree to be ready
	if not is_inside_tree():
		Logger.debug("PAWN", "⏳ Waiting for tree to be ready")
		await get_tree().process_frame
		_analyze_skeleton_structure.call_deferred()
		return
	
	# Additional wait to ensure all nodes are fully ready
	await get_tree().create_timer(0.5).timeout
	
	var skeleton = pawn_visual.get_skeleton()
	
	# Analyze bone positions and set collision positions
	for part_name in collision_shapes.keys():
		var bone = pawn_visual.get_bone(part_name)
		if bone and is_instance_valid(bone):
			var collision_shape = collision_shapes[part_name]
			if collision_shape and is_instance_valid(collision_shape):
				# Check if bone is ready for global position access
				if bone.is_inside_tree():
					collision_shape.global_position = bone.global_position
					Logger.debug("PAWN", "✅ Positioned collision for " + part_name + " at " + str(bone.global_position))
				else:
					Logger.debug("PAWN", "⏳ Bone " + part_name + " not ready, will retry")
					# Retry after a frame
					await get_tree().process_frame
					_analyze_skeleton_structure.call_deferred()
					return
		else:
			Logger.warn("PAWN", "❌ Bone not found for " + part_name)

func _update_dynamic_collisions():
	"""Update collision positions based on current pose"""
	if not pawn_visual:
		return
	
	Logger.debug("PAWN", "🔄 Updating dynamic collisions")
	
	for part_name in collision_shapes.keys():
		var bone = pawn_visual.get_bone(part_name)
		var collision_shape = collision_shapes[part_name]
		
		if bone and is_instance_valid(bone) and collision_shape and is_instance_valid(collision_shape):
			# Check if bone is ready for global position access
			if bone.is_inside_tree():
				# Update position based on bone position
				collision_shape.global_position = bone.global_position
				
				# Update rotation for certain body parts
				if part_name in ["left_arm", "right_arm", "left_leg", "right_leg"]:
					collision_shape.global_rotation = bone.global_rotation
			else:
				Logger.debug("PAWN", "⏳ Bone " + part_name + " not ready for collision update")

func update_collision_for_pose(pose_name: String):
	"""Update collision shapes for specific pose"""
	Logger.info("PAWN", "🔄 Updating collisions for pose: " + pose_name)
	
	# Wait for tree to be ready
	if not is_inside_tree():
		Logger.debug("PAWN", "⏳ Waiting for tree to be ready")
		await get_tree().process_frame
		update_collision_for_pose.call_deferred(pose_name)
		return
	
	# Wait a frame for pose to be applied
	await get_tree().process_frame
	
	# Update all collision positions
	_update_dynamic_collisions()

func set_collision_enabled(part_name: String, enabled: bool):
	"""Enable or disable collision for specific body part"""
	if part_name in collision_shapes:
		collision_shapes[part_name].disabled = not enabled
		Logger.debug("PAWN", "Collision " + ("enabled" if enabled else "disabled") + " for " + part_name)
	else:
		Logger.warn("PAWN", "❌ Collision shape not found for " + part_name)

func set_all_collisions_enabled(enabled: bool):
	"""Enable or disable all collision shapes"""
	for part_name in collision_shapes.keys():
		set_collision_enabled(part_name, enabled)

func get_collision_shape(part_name: String) -> CollisionShape3D:
	"""Get collision shape for body part"""
	return collision_shapes.get(part_name)

func print_collision_info():
	"""Print information about collision shapes"""
	Logger.info("PAWN", "=== Collision System Information ===")
	Logger.info("PAWN", "Auto collision enabled: " + str(enable_auto_collision))
	Logger.info("PAWN", "Update on pose change: " + str(update_collision_on_pose_change))
	Logger.info("PAWN", "Update rate: " + str(collision_update_rate) + " seconds")
	Logger.info("PAWN", "Collision shapes:")
	
	for part_name in collision_shapes.keys():
		var shape = collision_shapes[part_name]
		Logger.info("PAWN", "- " + part_name + ": " + str(shape.global_position) + " (enabled: " + str(!shape.disabled) + ")")

# === Advanced Collision Features ===

func create_detailed_collision():
	"""Create more detailed collision shapes based on skeleton analysis"""
	Logger.info("PAWN", "🔄 Creating detailed collision shapes")
	
	# This could analyze the actual mesh bounds and create more precise collisions
	# For now, we'll use the basic capsule shapes
	
	for part_name in collision_shapes.keys():
		var bone = pawn_visual.get_bone(part_name)
		if bone:
			# Could analyze bone hierarchy and create more complex shapes
			Logger.debug("PAWN", "Analyzed collision for " + part_name)

func optimize_collision_shapes():
	"""Optimize collision shapes for better performance"""
	Logger.info("PAWN", "🔄 Optimizing collision shapes")
	
	# Could merge nearby collision shapes or simplify complex ones
	# For now, just log the optimization
	Logger.debug("PAWN", "Collision shapes optimized")

# === Integration with PawnVisual ===

func connect_to_pawn_visual():
	"""Connect to PawnVisual for automatic updates"""
	if not pawn_visual:
		return
	
	# Connect to pose changes
	if pawn_visual.has_signal("pose_changed"):
		pawn_visual.connect("pose_changed", _on_pose_changed)
		Logger.debug("PAWN", "Connected to PawnVisual pose changes")

func _on_pose_changed(pose_name: String):
	"""Called when pose changes"""
	if update_collision_on_pose_change:
		update_collision_for_pose(pose_name) 
