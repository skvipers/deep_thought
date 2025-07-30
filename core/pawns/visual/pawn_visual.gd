extends Node3D
class_name PawnVisual

const Prosthesis = preload("res://addons/deep_thought/core/pawns/parts/prosthesis.gd")
const BodyStructure = preload("res://addons/deep_thought/core/pawns/parts/body_structure.gd")
const PawnSkeletonData = preload("res://addons/deep_thought/core/pawns/skeleton/pawn_skeleton_data.gd")
const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@onready var skeleton: Node3D = $Skeleton  # Can be PawnSkeleton or other skeleton types
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Automatically determine skeleton type
	if skeleton is PawnSkeleton:
		Logger.info("PAWN", "✅ Using enhanced PawnSkeleton")
	elif skeleton:
		Logger.info("PAWN", "ℹ️ Using basic skeleton: " + skeleton.get_class())
	else:
		Logger.warn("PAWN", "❌ No skeleton found")

func apply_body(body: BodyStructure):
	"""Apply body parts to skeleton"""
	if skeleton:
		if skeleton.has_method("apply_body_parts"):
			skeleton.apply_body_parts(body)
			Logger.debug("PAWN", "Applied body parts using skeleton method")
		else:
			_apply_body_fallback(body)
			Logger.debug("PAWN", "Applied body parts using fallback method")
	else:
		_apply_body_fallback(body)
		Logger.warn("PAWN", "No skeleton found, using fallback method")

func _apply_body_fallback(body: BodyStructure):
	"""Fallback method for applying body parts"""
	Logger.debug("PAWN", "Using fallback body application method")
	for part_name in body.parts:
		var part = body.parts[part_name]
		var attachment = get_attachment(part_name)
		
		if not attachment:
			Logger.warn("PAWN", "No attachment found for part: " + part_name)
			continue
		
		# Clear previous parts
		for child in attachment.get_children():
			child.queue_free()
		
		# Add new body part
		if part.prosthesis and part.prosthesis.visual_scene:
			var prosthesis_instance = part.prosthesis.visual_scene.instantiate()
			attachment.add_child(prosthesis_instance)
			Logger.debug("PAWN", "Added prosthesis to " + part_name)

func hide_part(part_name: String):
	"""Hide body part"""
	var attachment = get_attachment(part_name)
	if attachment:
		attachment.visible = false
		Logger.debug("PAWN", "Hidden part: " + part_name)
	else:
		Logger.warn("PAWN", "No attachment found for part: " + part_name)

func show_prosthesis(part_name: String, prosthesis: Prosthesis):
	"""Show prosthesis for body part"""
	var attachment = get_attachment(part_name)
	if attachment and prosthesis.visual_scene:
		# Clear previous parts
		for child in attachment.get_children():
			child.queue_free()
		
		# Add prosthesis
		var prosthesis_instance = prosthesis.visual_scene.instantiate()
		attachment.add_child(prosthesis_instance)
		attachment.visible = true
		Logger.debug("PAWN", "Showed prosthesis for " + part_name)
	else:
		Logger.warn("PAWN", "Could not show prosthesis for " + part_name)

func set_pose(pose_name: String):
	"""Set skeleton pose"""
	if skeleton and skeleton.has_method("set_pose"):
		skeleton.set_pose(pose_name)
		Logger.debug("PAWN", "Set pose via skeleton: " + pose_name)
	elif animation_player and animation_player.has_animation(pose_name):
		animation_player.play(pose_name)
		Logger.debug("PAWN", "Set pose via animation player: " + pose_name)
	else:
		Logger.warn("PAWN", "Could not set pose: " + pose_name)

# === Enhanced Skeleton Control Methods ===

func set_torso_rotation_with_following(rotation: Vector3):
	"""Sets torso rotation with automatic following of other parts"""
	if skeleton and skeleton.has_method("set_torso_rotation_with_following"):
		skeleton.set_torso_rotation_with_following(rotation)
		Logger.debug("PAWN", "Set torso rotation with following: " + str(rotation))
	else:
		Logger.warn("PAWN", "Torso following method not available")

func set_head_rotation_with_body_following(rotation: Vector3):
	"""Sets head rotation with body following"""
	if skeleton and skeleton.has_method("set_head_rotation_with_body_following"):
		skeleton.set_head_rotation_with_body_following(rotation)
		Logger.debug("PAWN", "Set head rotation with body following: " + str(rotation))
	else:
		Logger.warn("PAWN", "Head following method not available")

func set_arm_pose(side: String, pose_name: String):
	"""Set pose for arm with enhanced control"""
	if skeleton and skeleton.has_method("set_arm_pose"):
		skeleton.set_arm_pose(side, pose_name)
		Logger.debug("PAWN", "Set " + side + " arm pose: " + pose_name)
	else:
		Logger.warn("PAWN", "Arm pose method not available")

func set_leg_pose(side: String, pose_name: String):
	"""Set pose for leg with enhanced control"""
	if skeleton and skeleton.has_method("set_leg_pose"):
		skeleton.set_leg_pose(side, pose_name)
		Logger.debug("PAWN", "Set " + side + " leg pose: " + pose_name)
	else:
		Logger.warn("PAWN", "Leg pose method not available")

func reset_all_poses():
	"""Resets all poses to neutral position"""
	if skeleton and skeleton.has_method("reset_all_poses"):
		skeleton.reset_all_poses()
		Logger.debug("PAWN", "Reset all poses")
	else:
		Logger.warn("PAWN", "Reset poses method not available")

# === Bone Control Methods ===

func get_bone_transform(bone_name: String) -> Transform3D:
	"""Returns bone transform"""
	if skeleton and skeleton.has_method("get_bone_transform"):
		return skeleton.get_bone_transform(bone_name)
	return Transform3D.IDENTITY

func set_bone_transform(bone_name: String, transform: Transform3D):
	"""Set bone transform"""
	if skeleton and skeleton.has_method("set_bone_transform"):
		skeleton.set_bone_transform(bone_name, transform)
		Logger.debug("PAWN", "Set bone transform: " + bone_name)

func set_simple_bone_rotation(bone_name: String, rotation: Vector3):
	"""Set rotation for simple bone (Node3D)"""
	if skeleton and skeleton.has_method("set_simple_bone_rotation"):
		skeleton.set_simple_bone_rotation(bone_name, rotation)
		Logger.debug("PAWN", "Set simple bone rotation: " + bone_name + " = " + str(rotation))
	else:
		Logger.warn("PAWN", "Simple bone rotation method not available")

func set_skeleton_bone_rotation(bone_name: String, rotation: Vector3):
	"""Set rotation for skeleton bone (Skeleton3D)"""
	if skeleton and skeleton.has_method("set_skeleton_bone_rotation"):
		skeleton.set_skeleton_bone_rotation(bone_name, rotation)
		Logger.debug("PAWN", "Set skeleton bone rotation: " + bone_name + " = " + str(rotation))
	else:
		Logger.warn("PAWN", "Skeleton bone rotation method not available")

# === Skeleton Access Methods ===

func get_skeleton() -> Node3D:
	"""Returns skeleton"""
	return skeleton

func set_skeleton_data(skeleton_data: PawnSkeletonData):
	"""Set skeleton data"""
	if skeleton and skeleton.has_method("set_skeleton_data"):
		skeleton.skeleton_data = skeleton_data
		if skeleton.has_method("_setup_skeleton"):
			skeleton._setup_skeleton()  # Recreate skeleton
			Logger.debug("PAWN", "Skeleton data set and skeleton recreated")
		else:
			Logger.warn("PAWN", "Skeleton has no _setup_skeleton method")
	else:
		Logger.warn("PAWN", "Skeleton has no set_skeleton_data method")

func get_attachment(part_name: String) -> Node3D:
	"""Returns attachment for body part"""
	if skeleton and skeleton.has_method("get_attachment"):
		return skeleton.get_attachment(part_name)
	return null

func get_bone(bone_name: String) -> Node3D:
	"""Returns bone by name"""
	if skeleton and skeleton.has_method("get_bone"):
		return skeleton.get_bone(bone_name)
	return null

# === Bone Type Detection ===

func get_bone_type(bone_name: String) -> String:
	"""Returns bone type"""
	if skeleton and skeleton.has_method("get_bone_type"):
		return skeleton.get_bone_type(bone_name)
	
	# Fallback detection based on bone name
	if bone_name in ["head", "torso"]:
		return "simple"
	elif bone_name in ["left_arm", "right_arm", "left_leg", "right_leg"]:
		return "skeleton"
	return "unknown"

func get_simple_bone(bone_name: String) -> Node3D:
	"""Returns simple Node3D bone"""
	if skeleton and skeleton.has_method("get_simple_bone"):
		return skeleton.get_simple_bone(bone_name)
	return null

func get_skeleton_bone(bone_name: String) -> Skeleton3D:
	"""Returns Skeleton3D bone"""
	if skeleton and skeleton.has_method("get_skeleton_bone"):
		return skeleton.get_skeleton_bone(bone_name)
	return null

# === Following System Configuration ===

func configure_following_system(enable: bool = true, head_intensity: float = 0.3, torso_intensity: float = 0.2, arms_intensity: float = 0.4, legs_intensity: float = 0.3):
	"""Configure the automatic following system"""
	if skeleton and skeleton.has_method("configure_following_system"):
		skeleton.configure_following_system(enable, head_intensity, torso_intensity, arms_intensity, legs_intensity)
		Logger.debug("PAWN", "Configured following system")
	else:
		Logger.warn("PAWN", "Following system configuration not available")

func enable_automatic_following(enable: bool = true):
	"""Enable or disable automatic following"""
	if skeleton and "enable_automatic_following" in skeleton:
		skeleton.enable_automatic_following = enable
		Logger.debug("PAWN", "Automatic following " + ("enabled" if enable else "disabled"))
	else:
		Logger.warn("PAWN", "Automatic following setting not available")

# === Animation Integration ===

func play_animation(animation_name: String):
	"""Play animation with fallback to pose system"""
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		Logger.debug("PAWN", "Playing animation: " + animation_name)
	else:
		# Fallback to pose system
		set_pose(animation_name)
		Logger.debug("PAWN", "Using pose system for: " + animation_name)

func stop_animation():
	"""Stop current animation"""
	if animation_player:
		animation_player.stop()
		Logger.debug("PAWN", "Stopped animation")

func get_current_animation() -> String:
	"""Get current animation name"""
	if animation_player:
		return animation_player.current_animation
	return ""

# === Utility Methods ===

func get_bone_rotation(bone_name: String) -> Vector3:
	"""Get current rotation of bone"""
	if skeleton and skeleton.has_method("get_bone_rotation"):
		return skeleton.get_bone_rotation(bone_name)
	return Vector3.ZERO

func reset_bone_rotation(bone_name: String):
	"""Reset bone rotation to zero"""
	if skeleton and skeleton.has_method("reset_bone_rotation"):
		skeleton.reset_bone_rotation(bone_name)
		Logger.debug("PAWN", "Reset bone rotation: " + bone_name)

func reset_all_bones():
	"""Reset all bones to default rotation"""
	if skeleton and skeleton.has_method("reset_all_bones"):
		skeleton.reset_all_bones()
		Logger.debug("PAWN", "Reset all bones")

# === Debug Methods ===

func print_skeleton_info():
	"""Print detailed skeleton information"""
	if skeleton and skeleton.has_method("print_skeleton_info"):
		skeleton.print_skeleton_info()
	else:
		Logger.info("PAWN", "Skeleton info method not available")

func get_skeleton_data() -> PawnSkeletonData:
	"""Returns skeleton data"""
	if skeleton and skeleton.has_method("get_skeleton_data"):
		return skeleton.get_skeleton_data()
	return null
