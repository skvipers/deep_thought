extends Node3D
class_name PawnSkeleton

const UnifiedBoneData = preload("res://addons/deep_thought/core/pawns/skeleton/unified_bone_data.gd")
const AttachmentData = preload("res://addons/deep_thought/core/pawns/skeleton/attachment_data.gd")
const BodyStructure = preload("res://addons/deep_thought/core/pawns/parts/body_structure.gd")
const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@export var skeleton_data: PawnSkeletonData
@export var animation_player: AnimationPlayer
@export var default_pose: String = "idle"

var bones: Dictionary = {}
var bone_attachments: Dictionary = {}
var current_pose: Dictionary = {}

func _ready():
	if skeleton_data:
		_setup_skeleton()
		# Set default pose
		if default_pose:
			set_pose(default_pose)
			Logger.debug("PAWN", "Set default pose: " + default_pose)

func _setup_skeleton():
	"""Setup skeleton based on data"""
	if not skeleton_data:
		Logger.warn("PAWN", "No skeleton data provided")
		return
	
	Logger.info("PAWN", "Setting up skeleton with " + str(skeleton_data.bones.size()) + " bones")
	
	# Clear old bones and attachments
	_clear_skeleton()
	
	# Create bones
	for bone_data in skeleton_data.bones:
		var bone = _create_bone(bone_data)
		bones[bone_data.name] = bone
		add_child(bone)
		Logger.debug("PAWN", "Created bone: " + bone_data.name)
	
	# Create body part attachments
	for attachment_data in skeleton_data.attachments:
		var attachment = _create_attachment(attachment_data)
		bone_attachments[attachment_data.part_name] = attachment
		Logger.debug("PAWN", "Created attachment: " + attachment_data.part_name + " -> " + attachment_data.bone_name)
		# Attachments are already added as children to bones in _create_attachment

func _clear_skeleton():
	"""Clear old bones and attachments"""
	Logger.debug("PAWN", "Clearing skeleton")
	# Remove old bones
	for bone in bones.values():
		if bone and is_instance_valid(bone):
			bone.queue_free()
	
	# Clear dictionaries
	bones.clear()
	bone_attachments.clear()

func _create_bone(bone_data: UnifiedBoneData) -> Node3D:
	"""Create bone based on data"""
	var bone = Node3D.new()
	bone.name = bone_data.name
	bone.position = bone_data.position
	bone.rotation = bone_data.rotation
	return bone

func _create_attachment(attachment_data: AttachmentData) -> Node3D:
	"""Create attachment for body part"""
	var attachment = Node3D.new()
	attachment.name = "Attachment_" + attachment_data.part_name
	attachment.position = attachment_data.position
	attachment.rotation = attachment_data.rotation
	
	# Attach to corresponding bone
	var parent_bone = bones.get(attachment_data.bone_name)
	if parent_bone:
		parent_bone.add_child(attachment)
		Logger.debug("PAWN", "Attached " + attachment_data.part_name + " to bone " + attachment_data.bone_name)
	else:
		Logger.warn("PAWN", "Parent bone not found: " + attachment_data.bone_name)
	
	return attachment

func get_skeleton_data() -> PawnSkeletonData:
	"""Returns skeleton data"""
	return skeleton_data

func get_bone(name: String) -> Node3D:
	"""Returns bone by name"""
	return bones.get(name)

func get_attachment(part_name: String) -> Node3D:
	"""Returns attachment for body part"""
	return bone_attachments.get(part_name)

func set_pose(pose_name: String):
	"""Set skeleton pose"""
	if not animation_player:
		Logger.warn("PAWN", "No animation player found")
		return
	
	if animation_player.has_animation(pose_name):
		animation_player.play(pose_name)
		current_pose = {"name": pose_name}
		Logger.debug("PAWN", "Set pose: " + pose_name)
	else:
		Logger.warn("PAWN", "Animation not found: " + pose_name)

func get_default_pose() -> String:
	"""Returns default pose"""
	return default_pose 
