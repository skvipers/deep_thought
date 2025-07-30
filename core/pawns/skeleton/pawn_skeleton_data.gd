extends Resource
class_name PawnSkeletonData

const UnifiedBoneData = preload("res://addons/deep_thought/core/pawns/skeleton/unified_bone_data.gd")
const AttachmentData = preload("res://addons/deep_thought/core/pawns/skeleton/attachment_data.gd")
const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@export var bones: Array[UnifiedBoneData] = []
@export var attachments: Array[AttachmentData] = []
@export var default_pose: String = "idle"

func get_bone_data(bone_name: String) -> UnifiedBoneData:
	"""Returns bone data by name"""
	for bone in bones:
		if bone.name == bone_name:
			return bone
	return null

func add_bone(bone_data: UnifiedBoneData):
	"""Adds bone to skeleton"""
	bones.append(bone_data)
	Logger.debug("PAWN", "Added bone: " + bone_data.name)

func get_simple_bones() -> Array[UnifiedBoneData]:
	"""Returns only simple bones"""
	var simple_bones: Array[UnifiedBoneData] = []
	for bone in bones:
		if bone.is_simple():
			simple_bones.append(bone)
	return simple_bones

func get_skeleton_bones() -> Array[UnifiedBoneData]:
	"""Returns only skeletal bones"""
	var skeleton_bones: Array[UnifiedBoneData] = []
	for bone in bones:
		if bone.is_skeleton():
			skeleton_bones.append(bone)
	return skeleton_bones

func get_simple_bone_names() -> Array[String]:
	"""Returns simple bone names"""
	var names: Array[String] = []
	for bone in get_simple_bones():
		names.append(bone.name)
	return names

func get_skeleton_bone_names() -> Array[String]:
	"""Returns skeletal bone names"""
	var names: Array[String] = []
	for bone in get_skeleton_bones():
		names.append(bone.name)
	return names

func add_attachment(attachment: AttachmentData):
	"""Adds attachment"""
	attachments.append(attachment)
	Logger.debug("PAWN", "Added attachment: " + attachment.part_name + " -> " + attachment.bone_name)

func print_skeleton_info():
	"""Prints skeleton structure information"""
	Logger.info("PAWN", "=== Skeleton Information ===")
	Logger.info("PAWN", "Total bones: " + str(bones.size()))
	Logger.info("PAWN", "Total attachments: " + str(attachments.size()))
	
	Logger.info("PAWN", "Simple bones:")
	for bone in get_simple_bones():
		Logger.info("PAWN", "- " + bone.name + " (" + str(bone.position) + ")")
		if bone.child_bones.size() > 0:
			Logger.info("PAWN", "  Children: " + str(bone.child_bones))
	
	Logger.info("PAWN", "Skeletal bones:")
	for bone in get_skeleton_bones():
		Logger.info("PAWN", "- " + bone.name + " (" + str(bone.position) + ")")
		if bone.joint_names.size() > 0:
			Logger.info("PAWN", "  Joints: " + str(bone.joint_names))
	
	Logger.info("PAWN", "Attachments:")
	for attachment in attachments:
		Logger.info("PAWN", "- " + attachment.part_name + " → " + attachment.bone_name) 
