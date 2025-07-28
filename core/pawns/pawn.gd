extends Node3D
class_name Pawn

const Prosthesis = preload("res://addons/deep_thought/core/pawns/parts/prosthesis.gd")
const BodyStructure = preload("res://addons/deep_thought/core/pawns/parts/body_structure.gd")
const PawnSkeletonData = preload("res://addons/deep_thought/core/pawns/skeleton/pawn_skeleton_data.gd")
const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@export var config: PawnConfig
@onready var visual := $Visual

var stats: StatBlock
var body: BodyStructure
var skeleton: Node3D  # Can be PawnSkeleton or AutoSkeletonController

func _ready():
	if config:
		Logger.info("PAWN", "Initializing pawn with config")
		stats = config.base_stats.duplicate()
		body = config.body_structure.duplicate()
		_apply_prosthetics()
		
		if visual:
			visual.apply_body(body)
			if config:
				var skeleton_data = config.get_skeleton_data()
				if skeleton_data and visual.get_skeleton():
					visual.set_skeleton_data(skeleton_data)
					skeleton = visual.get_skeleton()
					Logger.debug("PAWN", "Skeleton initialized")
				else:
					Logger.warn("PAWN", "Failed to initialize skeleton")
		else:
			Logger.warn("PAWN", "No visual component found")
	else:
		Logger.warn("PAWN", "No config provided")

func _apply_prosthetics():
	"""Apply prosthetics to body parts"""
	Logger.debug("PAWN", "Applying prosthetics")
	for part_name in body.parts:
		var part = body.parts[part_name]
		if part.prosthesis:
			part.prosthesis.apply_to_part(part)
			Logger.debug("PAWN", "Applied prosthesis to " + part_name)

func set_pose(pose_name: String):
	"""Set pawn pose"""
	if visual:
		visual.set_pose(pose_name)
		Logger.debug("PAWN", "Set pose: " + pose_name)
	else:
		Logger.warn("PAWN", "No visual component for pose setting")

func get_default_pose() -> String:
	"""Returns default pose from skeleton"""
	if skeleton and skeleton.has_method("get_default_pose"):
		return skeleton.get_default_pose()
	return "idle"

func set_default_pose():
	"""Set default pose"""
	var default_pose = get_default_pose()
	set_pose(default_pose)
	Logger.debug("PAWN", "Set default pose: " + default_pose)

func get_bone_transform(bone_name: String) -> Transform3D:
	"""Returns bone transform"""
	if visual:
		return visual.get_bone_transform(bone_name)
	return Transform3D.IDENTITY

func set_bone_transform(bone_name: String, transform: Transform3D):
	"""Set bone transform"""
	if visual:
		visual.set_bone_transform(bone_name, transform)
		Logger.debug("PAWN", "Set bone transform: " + bone_name)

func get_skeleton() -> Node3D:
	"""Returns pawn skeleton"""
	return skeleton

func apply_damage_to_part(part_name: String, damage: int):
	"""Apply damage to body part"""
	if body.parts.has(part_name):
		var part = body.parts[part_name]
		part.current_health = max(0, part.current_health - damage)
		Logger.info("PAWN", "Applied " + str(damage) + " damage to " + part_name + " (health: " + str(part.current_health) + ")")
		
		# Update visual
		if visual:
			visual.apply_body(body)
	else:
		Logger.warn("PAWN", "Body part not found: " + part_name)

func heal_part(part_name: String, heal_amount: int):
	"""Heal body part"""
	if body.parts.has(part_name):
		var part = body.parts[part_name]
		part.current_health = min(part.max_health, part.current_health + heal_amount)
		Logger.info("PAWN", "Healed " + part_name + " by " + str(heal_amount) + " (health: " + str(part.current_health) + ")")
		
		# Update visual
		if visual:
			visual.apply_body(body)
	else:
		Logger.warn("PAWN", "Body part not found: " + part_name)

func install_prosthesis(part_name: String, prosthesis: Prosthesis):
	"""Install prosthesis on body part"""
	if body.parts.has(part_name):
		var part = body.parts[part_name]
		part.prosthesis = prosthesis
		Logger.info("PAWN", "Installed prosthesis on " + part_name)
		
		# Update visual
		if visual:
			visual.apply_body(body)
	else:
		Logger.warn("PAWN", "Body part not found: " + part_name)

func get_part_health(part_name: String) -> int:
	"""Returns body part health"""
	if body.parts.has(part_name):
		return body.parts[part_name].current_health
	return 0

func get_part_max_health(part_name: String) -> int:
	"""Returns maximum body part health"""
	if body.parts.has(part_name):
		return body.parts[part_name].max_health
	return 0

# Methods for hybrid skeleton
func set_skeleton_bone_pose(bone_name: String, pose_name: String):
	"""Sets pose for Skeleton3D bone"""
	if visual:
		visual.set_skeleton_bone_pose(bone_name, pose_name)

func set_skeleton_bone_joint_rotation(bone_name: String, joint_index: int, rotation: Vector3):
	"""Sets joint rotation for Skeleton3D bone"""
	if visual:
		visual.set_skeleton_bone_joint_rotation(bone_name, joint_index, rotation)

func get_bone_type(bone_name: String) -> String:
	"""Returns bone type"""
	if visual:
		return visual.get_bone_type(bone_name)
	return "unknown"

func get_skeleton_bone(bone_name: String) -> Skeleton3D:
	"""Returns Skeleton3D bone"""
	if visual:
		return visual.get_skeleton_bone(bone_name)
	return null

func get_simple_bone(bone_name: String) -> Node3D:
	"""Returns simple Node3D bone"""
	if visual:
		return visual.get_simple_bone(bone_name)
	return null
