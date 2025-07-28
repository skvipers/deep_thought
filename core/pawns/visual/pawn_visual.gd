extends Node3D
class_name PawnVisual

const Prosthesis = preload("res://addons/deep_thought/core/pawns/parts/prosthesis.gd")
const BodyStructure = preload("res://addons/deep_thought/core/pawns/parts/body_structure.gd")
const PawnSkeletonData = preload("res://addons/deep_thought/core/pawns/skeleton/pawn_skeleton_data.gd")
const AutoSkeletonController = preload("res://addons/deep_thought/core/pawns/skeleton/auto_skeleton_controller.gd")
const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@onready var skeleton: Node3D = $Skeleton  # Can be PawnSkeleton or AutoSkeletonController
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Automatically determine skeleton type
	if skeleton is AutoSkeletonController:
		Logger.info("PAWN", "Using AutoSkeletonController")
	elif skeleton is PawnSkeleton:
		Logger.info("PAWN", "Using PawnSkeleton")
	else:
		Logger.info("PAWN", "Using basic skeleton")

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

# Methods for the auto skeleton controller
func set_skeleton_bone_pose(bone_name: String, pose_name: String):
	"""Sets pose for Skeleton3D bone"""
	if skeleton is AutoSkeletonController:
		if bone_name.begins_with("left_arm"):
			skeleton.set_arm_pose("left", pose_name)
		elif bone_name.begins_with("right_arm"):
			skeleton.set_arm_pose("right", pose_name)
		elif bone_name.begins_with("left_leg"):
			skeleton.set_leg_pose("left", pose_name)
		elif bone_name.begins_with("right_leg"):
			skeleton.set_leg_pose("right", pose_name)

func set_skeleton_bone_joint_rotation(bone_name: String, joint_index: int, rotation: Vector3):
	"""Sets joint rotation for Skeleton3D bone"""
	if skeleton is AutoSkeletonController:
		# For the auto controller, we use standard methods
		if bone_name.begins_with("head"):
			skeleton.rotate_head(rotation)
		elif bone_name.begins_with("torso"):
			skeleton.rotate_torso(rotation)

func get_bone_type(bone_name: String) -> String:
	"""Returns bone type"""
	if skeleton is AutoSkeletonController:
		# Determine type based on bone name
		if bone_name in ["head", "torso"]:
			return "simple"
		elif bone_name in ["left_arm", "right_arm", "left_leg", "right_leg"]:
			return "skeleton"
	return "unknown"

func get_skeleton_bone(bone_name: String) -> Skeleton3D:
	"""Returns Skeleton3D bone"""
	if skeleton is AutoSkeletonController:
		# Return the corresponding skeleton
		if bone_name.begins_with("left_arm") or bone_name.begins_with("right_arm"):
			return skeleton.arm_skeleton
		elif bone_name.begins_with("left_leg") or bone_name.begins_with("right_leg"):
			return skeleton.leg_skeleton
	return null

func get_simple_bone(bone_name: String) -> Node3D:
	"""Returns simple Node3D bone"""
	if skeleton is AutoSkeletonController:
		# Return the corresponding simple bones
		if bone_name == "head":
			return skeleton.head_bone
		elif bone_name == "torso":
			return skeleton.torso_bone
	return null
