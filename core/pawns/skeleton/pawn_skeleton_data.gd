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

func create_humanoid_skeleton() -> PawnSkeletonData:
	"""Creates basic humanoid skeleton"""
	var skeleton = PawnSkeletonData.new()
	Logger.info("PAWN", "Creating humanoid skeleton")
	
	# Simple bones
	var head_bone = UnifiedBoneData.new()
	head_bone.setup_simple_bone("head", "head", "head/head_mesh")
	skeleton.add_bone(head_bone)
	
	var torso_bone = UnifiedBoneData.new()
	torso_bone.setup_simple_bone("torso", "torso", "torso/torso_mesh", ["chest", "waist"])
	skeleton.add_bone(torso_bone)
	
	# Skeletal bones
	var left_arm_bone = UnifiedBoneData.new()
	left_arm_bone.setup_skeleton_bone("left_arm", "left_arm/ArmSkeleton", "left_arm/ArmSkeleton/left_arm_mesh", ["Shoulder", "Elbow"])
	skeleton.add_bone(left_arm_bone)
	
	var right_arm_bone = UnifiedBoneData.new()
	right_arm_bone.setup_skeleton_bone("right_arm", "right_arm/ArmSkeleton", "right_arm/ArmSkeleton/right_arm_mesh", ["Shoulder", "Elbow"])
	skeleton.add_bone(right_arm_bone)
	
	var left_leg_bone = UnifiedBoneData.new()
	left_leg_bone.setup_skeleton_bone("left_leg", "left_leg/LegSkeleton", "left_leg/LegSkeleton/left_leg_mesh", ["Hip", "Knee"])
	skeleton.add_bone(left_leg_bone)
	
	var right_leg_bone = UnifiedBoneData.new()
	right_leg_bone.setup_skeleton_bone("right_leg", "right_leg/LegSkeleton", "right_leg/LegSkeleton/right_leg_mesh", ["Hip", "Knee"])
	skeleton.add_bone(right_leg_bone)
	
	# Body part attachments
	skeleton.add_attachment(AttachmentData.new("head", "head", Vector3.ZERO, Vector3.ZERO))
	skeleton.add_attachment(AttachmentData.new("torso", "torso", Vector3.ZERO, Vector3.ZERO))
	skeleton.add_attachment(AttachmentData.new("left_arm", "left_arm", Vector3.ZERO, Vector3.ZERO))
	skeleton.add_attachment(AttachmentData.new("right_arm", "right_arm", Vector3.ZERO, Vector3.ZERO))
	skeleton.add_attachment(AttachmentData.new("left_leg", "left_leg", Vector3.ZERO, Vector3.ZERO))
	skeleton.add_attachment(AttachmentData.new("right_leg", "right_leg", Vector3.ZERO, Vector3.ZERO))
	
	Logger.info("PAWN", "Humanoid skeleton created with " + str(skeleton.bones.size()) + " bones and " + str(skeleton.attachments.size()) + " attachments")
	return skeleton

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
