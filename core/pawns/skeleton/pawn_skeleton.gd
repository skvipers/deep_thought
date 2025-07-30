extends Node3D
class_name PawnSkeleton

const UnifiedBoneData = preload("res://addons/deep_thought/core/pawns/skeleton/unified_bone_data.gd")
const AttachmentData = preload("res://addons/deep_thought/core/pawns/skeleton/attachment_data.gd")
const BodyStructure = preload("res://addons/deep_thought/core/pawns/parts/body_structure.gd")
const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@export var skeleton_data: PawnSkeletonData
@export var animation_player: AnimationPlayer
@export var default_pose: String = "idle"

# Enhanced bone references for better control
var head_bone: Node3D
var torso_bone: Node3D
var left_arm_skeleton: Skeleton3D
var right_arm_skeleton: Skeleton3D
var left_leg_skeleton: Skeleton3D
var right_leg_skeleton: Skeleton3D

# Following system settings
@export_group("Following System")
@export var enable_automatic_following: bool = true
@export var head_follow_torso_intensity: float = 0.3
@export var torso_follow_head_intensity: float = 0.2
@export var arms_follow_torso_intensity: float = 0.4
@export var legs_follow_torso_intensity: float = 0.3

var bones: Dictionary = {}
var bone_attachments: Dictionary = {}
var current_pose: Dictionary = {}

func _ready():
	if skeleton_data:
		_setup_skeleton()
		_enhanced_auto_find_nodes()
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
	
	# Find existing bones in scene
	for bone_data in skeleton_data.bones:
		var bone = _create_bone(bone_data)
		if bone:
			bones[bone_data.name] = bone
			Logger.info("PAWN", "✅ Found bone: " + bone_data.name + " (type: " + ("skeleton" if bone_data.bone_type == UnifiedBoneData.BoneType.SKELETON else "simple") + ")")
		else:
			Logger.warn("PAWN", "❌ Failed to find bone: " + bone_data.name)
	
	# Create body part attachments
	for attachment_data in skeleton_data.attachments:
		var attachment = _create_attachment(attachment_data)
		bone_attachments[attachment_data.part_name] = attachment
		Logger.debug("PAWN", "Created attachment: " + attachment_data.part_name + " -> " + attachment_data.bone_name)
	
	Logger.info("PAWN", "🎯 Skeleton setup complete! Bones: " + str(bones.keys()))

func _enhanced_auto_find_nodes():
	"""Enhanced automatic node finding with better error handling"""
	Logger.info("PAWN", "🔍 Starting enhanced node search...")
	
	# Find simple bones
	head_bone = _find_node_by_name("head")
	torso_bone = _find_node_by_name("torso")
	
	# Find skeleton bones
	left_arm_skeleton = _find_skeleton_by_name("left_arm", "ArmSkeleton")
	right_arm_skeleton = _find_skeleton_by_name("right_arm", "ArmSkeleton")
	left_leg_skeleton = _find_skeleton_by_name("left_leg", "LegSkeleton")
	right_leg_skeleton = _find_skeleton_by_name("right_leg", "LegSkeleton")
	
	_print_enhanced_found_nodes()

func _find_node_by_name(name: String) -> Node3D:
	"""Find node by name with better error handling"""
	var node = get_node_or_null(name)
	if node:
		Logger.debug("PAWN", "✅ Found node: " + name)
		return node
	else:
		Logger.warn("PAWN", "❌ Node not found: " + name)
		return null

func _find_skeleton_by_name(bone_name: String, skeleton_name: String) -> Skeleton3D:
	"""Find skeleton by name with better error handling"""
	var path = bone_name + "/" + skeleton_name
	var node = get_node_or_null(path)
	if node and node is Skeleton3D:
		Logger.debug("PAWN", "✅ Found skeleton: " + path)
		return node as Skeleton3D
	else:
		Logger.warn("PAWN", "❌ Skeleton not found: " + path)
		return null

func _print_enhanced_found_nodes():
	"""Print detailed information about found nodes"""
	Logger.info("PAWN", "=== Enhanced Node Search Results ===")
	Logger.info("PAWN", "Simple bones:")
	Logger.info("PAWN", "- Head: " + str(head_bone != null) + " (" + str(head_bone.get_path() if head_bone else "N/A") + ")")
	Logger.info("PAWN", "- Torso: " + str(torso_bone != null) + " (" + str(torso_bone.get_path() if torso_bone else "N/A") + ")")
	Logger.info("PAWN", "Skeleton bones:")
	Logger.info("PAWN", "- Left arm: " + str(left_arm_skeleton != null))
	Logger.info("PAWN", "- Right arm: " + str(right_arm_skeleton != null))
	Logger.info("PAWN", "- Left leg: " + str(left_leg_skeleton != null))
	Logger.info("PAWN", "- Right leg: " + str(right_leg_skeleton != null))

func _clear_skeleton():
	"""Clear old bones and attachments"""
	Logger.debug("PAWN", "Clearing skeleton references")
	# Don't delete existing nodes, just clear references
	bones.clear()
	bone_attachments.clear()

func _create_bone(bone_data: UnifiedBoneData) -> Node3D:
	"""Get or create bone based on data"""
	if bone_data.bone_type == UnifiedBoneData.BoneType.SKELETON:
		# Find existing Skeleton3D in the scene
		var skeleton_path = bone_data.skeleton_path
		if skeleton_path.is_empty():
			skeleton_path = bone_data.node_path
		
		var skeleton = get_node_or_null(skeleton_path)
		if skeleton and skeleton is Skeleton3D:
			Logger.info("PAWN", "✅ Found existing skeleton: " + skeleton_path)
			return skeleton
		else:
			Logger.warn("PAWN", "❌ Skeleton not found at path: " + skeleton_path)
			return null
	else:
		# Find existing Node3D in the scene
		var node_path = bone_data.node_path
		var node = get_node_or_null(node_path)
		if node:
			Logger.info("PAWN", "✅ Found existing node: " + node_path)
			return node
		else:
			Logger.warn("PAWN", "❌ Node not found at path: " + node_path)
			return null

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

# === Enhanced Bone Control Methods ===

func set_simple_bone_rotation(bone_name: String, rotation: Vector3):
	"""Set rotation for simple bone (Node3D) with enhanced logging"""
	Logger.info("PAWN", "🔄 Attempting to rotate bone: " + bone_name + " to: " + str(rotation))
	
	var bone = get_bone(bone_name)
	if bone:
		bone.rotation = rotation
		Logger.info("PAWN", "✅ Rotation applied to bone '" + bone_name + "': " + str(rotation))
		Logger.info("PAWN", "   Bone path: " + str(bone.get_path()))
		Logger.info("PAWN", "   Bone transform: " + str(bone.transform))
	else:
		Logger.warn("PAWN", "❌ Bone not found: " + bone_name)

func set_skeleton_bone_rotation(bone_name: String, rotation: Vector3):
	"""Set rotation for skeleton bone (Skeleton3D) with enhanced control"""
	var bone = get_bone(bone_name)
	if bone and bone is Skeleton3D:
		var skeleton = bone as Skeleton3D
		Logger.info("PAWN", "🔄 Rotating skeleton bone: " + bone_name + " to: " + str(rotation))
		
		# Apply rotation to all bones in the skeleton
		for bone_idx in range(skeleton.get_bone_count()):
			var transform = skeleton.get_bone_pose(bone_idx)
			transform.basis = Basis.from_euler(rotation)
			skeleton.set_bone_pose(bone_idx, transform)
			Logger.info("PAWN", "✅ Applied rotation to bone " + str(bone_idx) + " in skeleton: " + bone_name)
	else:
		Logger.warn("PAWN", "❌ Skeleton bone not found or invalid: " + bone_name)

# === Enhanced Automatic Following System ===

func set_torso_rotation_with_following(rotation: Vector3):
	"""Sets torso rotation and makes other parts follow automatically"""
	if not enable_automatic_following:
		set_simple_bone_rotation("torso", rotation)
		return
	
	Logger.info("PAWN", "🔄 Setting torso rotation with following: " + str(rotation))
	
	if torso_bone:
		torso_bone.rotation = rotation
		Logger.info("PAWN", "✅ Torso rotation applied")
		
		# Make head follow torso with configurable intensity
		if head_bone:
			var head_offset = Vector3(0, 0, rotation.z * head_follow_torso_intensity)
			head_bone.rotation = head_offset
			Logger.info("PAWN", "✅ Head following torso with offset: " + str(head_offset))
		
		# Make arms follow torso
		_make_arms_follow_torso(rotation)
		
		# Make legs follow torso
		_make_legs_follow_torso(rotation)
	else:
		Logger.warn("PAWN", "❌ Torso bone not found")

func set_head_rotation_with_body_following(rotation: Vector3):
	"""Sets head rotation and makes body follow slightly"""
	if not enable_automatic_following:
		set_simple_bone_rotation("head", rotation)
		return
	
	Logger.info("PAWN", "🔄 Setting head rotation with body following: " + str(rotation))
	
	if head_bone:
		head_bone.rotation = rotation
		Logger.info("PAWN", "✅ Head rotation applied")
		
		# Make torso follow head with reduced intensity
		if torso_bone:
			var torso_offset = Vector3(0, 0, rotation.z * torso_follow_head_intensity)
			torso_bone.rotation = torso_offset
			Logger.info("PAWN", "✅ Torso following head with offset: " + str(torso_offset))
	else:
		Logger.warn("PAWN", "❌ Head bone not found")

func _make_arms_follow_torso(torso_rotation: Vector3):
	"""Makes arms follow torso rotation with configurable intensity"""
	Logger.info("PAWN", "🔄 Making arms follow torso")
	
	var arm_offset = Vector3(0, 0, torso_rotation.z * arms_follow_torso_intensity)
	
	# Left arm
	if left_arm_skeleton:
		var shoulder_bone = left_arm_skeleton.find_bone("Shoulder")
		if shoulder_bone >= 0:
			var pose = left_arm_skeleton.get_bone_pose(shoulder_bone)
			pose.basis = Basis.from_euler(arm_offset)
			left_arm_skeleton.set_bone_pose(shoulder_bone, pose)
			Logger.debug("PAWN", "✅ Left arm following torso")
	
	# Right arm
	if right_arm_skeleton:
		var shoulder_bone = right_arm_skeleton.find_bone("Shoulder")
		if shoulder_bone >= 0:
			var pose = right_arm_skeleton.get_bone_pose(shoulder_bone)
			pose.basis = Basis.from_euler(arm_offset)
			right_arm_skeleton.set_bone_pose(shoulder_bone, pose)
			Logger.debug("PAWN", "✅ Right arm following torso")

func _make_legs_follow_torso(torso_rotation: Vector3):
	"""Makes legs follow torso rotation with configurable intensity"""
	Logger.info("PAWN", "🔄 Making legs follow torso")
	
	var leg_offset = Vector3(0, 0, torso_rotation.z * legs_follow_torso_intensity)
	
	# Left leg
	if left_leg_skeleton:
		var hip_bone = left_leg_skeleton.find_bone("Hip")
		if hip_bone >= 0:
			var pose = left_leg_skeleton.get_bone_pose(hip_bone)
			pose.basis = Basis.from_euler(leg_offset)
			left_leg_skeleton.set_bone_pose(hip_bone, pose)
			Logger.debug("PAWN", "✅ Left leg following torso")
	
	# Right leg
	if right_leg_skeleton:
		var hip_bone = right_leg_skeleton.find_bone("Hip")
		if hip_bone >= 0:
			var pose = right_leg_skeleton.get_bone_pose(hip_bone)
			pose.basis = Basis.from_euler(leg_offset)
			right_leg_skeleton.set_bone_pose(hip_bone, pose)
			Logger.debug("PAWN", "✅ Right leg following torso")

# === Enhanced Pose System ===

func set_arm_pose(side: String, pose_name: String):
	"""Set pose for arm with enhanced control"""
	var skeleton = left_arm_skeleton if side == "left" else right_arm_skeleton
	if not skeleton:
		Logger.warn("PAWN", "❌ " + side + " arm skeleton not found")
		return
	
	Logger.info("PAWN", "🔄 Setting " + side + " arm pose: " + pose_name)
	
	match pose_name:
		"idle":
			_set_arm_idle_pose(skeleton, side)
		"raised":
			_set_arm_raised_pose(skeleton, side)
		"pointing":
			_set_arm_pointing_pose(skeleton, side)
		"bent":
			_set_arm_bent_pose(skeleton, side)
		_:
			Logger.warn("PAWN", "❌ Unknown arm pose: " + pose_name)

func set_leg_pose(side: String, pose_name: String):
	"""Set pose for leg with enhanced control"""
	var skeleton = left_leg_skeleton if side == "left" else right_leg_skeleton
	if not skeleton:
		Logger.warn("PAWN", "❌ " + side + " leg skeleton not found")
		return
	
	Logger.info("PAWN", "🔄 Setting " + side + " leg pose: " + pose_name)
	
	match pose_name:
		"idle":
			_set_leg_idle_pose(skeleton, side)
		"walking":
			_set_leg_walking_pose(skeleton, side)
		"kicking":
			_set_leg_kicking_pose(skeleton, side)
		_:
			Logger.warn("PAWN", "❌ Unknown leg pose: " + pose_name)

# === Pose Implementation Methods ===

func _set_arm_idle_pose(skeleton: Skeleton3D, side: String):
	"""Sets idle pose for arm"""
	var shoulder_bone = skeleton.find_bone("Shoulder")
	var elbow_bone = skeleton.find_bone("Elbow")
	
	if shoulder_bone >= 0:
		var pose = skeleton.get_bone_pose(shoulder_bone)
		pose.basis = Basis.from_euler(Vector3.ZERO)
		skeleton.set_bone_pose(shoulder_bone, pose)
	
	if elbow_bone >= 0:
		var pose = skeleton.get_bone_pose(elbow_bone)
		pose.basis = Basis.from_euler(Vector3.ZERO)
		skeleton.set_bone_pose(elbow_bone, pose)
	
	Logger.debug("PAWN", "✅ Idle pose set for " + side + " arm")

func _set_arm_raised_pose(skeleton: Skeleton3D, side: String):
	"""Sets raised arm pose"""
	var shoulder_bone = skeleton.find_bone("Shoulder")
	var elbow_bone = skeleton.find_bone("Elbow")
	
	if shoulder_bone >= 0:
		var pose = skeleton.get_bone_pose(shoulder_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, deg_to_rad(90)))
		skeleton.set_bone_pose(shoulder_bone, pose)
	
	if elbow_bone >= 0:
		var pose = skeleton.get_bone_pose(elbow_bone)
		pose.basis = Basis.from_euler(Vector3.ZERO)
		skeleton.set_bone_pose(elbow_bone, pose)
	
	Logger.debug("PAWN", "✅ " + side + " arm raised")

func _set_arm_pointing_pose(skeleton: Skeleton3D, side: String):
	"""Sets pointing pose"""
	var shoulder_bone = skeleton.find_bone("Shoulder")
	var elbow_bone = skeleton.find_bone("Elbow")
	
	if shoulder_bone >= 0:
		var pose = skeleton.get_bone_pose(shoulder_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, deg_to_rad(45)))
		skeleton.set_bone_pose(shoulder_bone, pose)
	
	if elbow_bone >= 0:
		var pose = skeleton.get_bone_pose(elbow_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, deg_to_rad(90)))
		skeleton.set_bone_pose(elbow_bone, pose)
	
	Logger.debug("PAWN", "✅ " + side + " arm is pointing")

func _set_arm_bent_pose(skeleton: Skeleton3D, side: String):
	"""Sets bent arm pose"""
	var shoulder_bone = skeleton.find_bone("Shoulder")
	var elbow_bone = skeleton.find_bone("Elbow")
	
	if shoulder_bone >= 0:
		var pose = skeleton.get_bone_pose(shoulder_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, deg_to_rad(30)))
		skeleton.set_bone_pose(shoulder_bone, pose)
	
	if elbow_bone >= 0:
		var pose = skeleton.get_bone_pose(elbow_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, deg_to_rad(120)))
		skeleton.set_bone_pose(elbow_bone, pose)
	
	Logger.debug("PAWN", "✅ " + side + " arm bent")

func _set_leg_idle_pose(skeleton: Skeleton3D, side: String):
	"""Sets idle pose for leg"""
	var hip_bone = skeleton.find_bone("Hip")
	var knee_bone = skeleton.find_bone("Knee")
	
	if hip_bone >= 0:
		var pose = skeleton.get_bone_pose(hip_bone)
		pose.basis = Basis.from_euler(Vector3.ZERO)
		skeleton.set_bone_pose(hip_bone, pose)
	
	if knee_bone >= 0:
		var pose = skeleton.get_bone_pose(knee_bone)
		pose.basis = Basis.from_euler(Vector3.ZERO)
		skeleton.set_bone_pose(knee_bone, pose)
	
	Logger.debug("PAWN", "✅ Idle pose set for " + side + " leg")

func _set_leg_walking_pose(skeleton: Skeleton3D, side: String):
	"""Sets walking pose"""
	var hip_bone = skeleton.find_bone("Hip")
	var knee_bone = skeleton.find_bone("Knee")
	
	if hip_bone >= 0:
		var pose = skeleton.get_bone_pose(hip_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, deg_to_rad(30)))
		skeleton.set_bone_pose(hip_bone, pose)
	
	if knee_bone >= 0:
		var pose = skeleton.get_bone_pose(knee_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, deg_to_rad(60)))
		skeleton.set_bone_pose(knee_bone, pose)
	
	Logger.debug("PAWN", "✅ " + side + " leg in walking pose")

func _set_leg_kicking_pose(skeleton: Skeleton3D, side: String):
	"""Sets kicking pose"""
	var hip_bone = skeleton.find_bone("Hip")
	var knee_bone = skeleton.find_bone("Knee")
	
	if hip_bone >= 0:
		var pose = skeleton.get_bone_pose(hip_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, deg_to_rad(45)))
		skeleton.set_bone_pose(hip_bone, pose)
	
	if knee_bone >= 0:
		var pose = skeleton.get_bone_pose(knee_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, deg_to_rad(90)))
		skeleton.set_bone_pose(knee_bone, pose)
	
	Logger.debug("PAWN", "✅ " + side + " leg in kicking pose")

# === Following System Configuration ===

func configure_following_system(enable: bool = true, head_intensity: float = 0.3, torso_intensity: float = 0.2, arms_intensity: float = 0.4, legs_intensity: float = 0.3):
	"""Configure the automatic following system"""
	enable_automatic_following = enable
	head_follow_torso_intensity = head_intensity
	torso_follow_head_intensity = torso_intensity
	arms_follow_torso_intensity = arms_intensity
	legs_follow_torso_intensity = legs_intensity
	
	Logger.info("PAWN", "🔄 Configured following system:")
	Logger.info("PAWN", "  - Enabled: " + str(enable))
	Logger.info("PAWN", "  - Head follow torso: " + str(head_intensity))
	Logger.info("PAWN", "  - Torso follow head: " + str(torso_intensity))
	Logger.info("PAWN", "  - Arms follow torso: " + str(arms_intensity))
	Logger.info("PAWN", "  - Legs follow torso: " + str(legs_intensity))

# === Utility Methods ===

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

func reset_all_poses():
	"""Resets all poses to neutral position"""
	Logger.info("PAWN", "🔄 Resetting all poses to neutral")
	
	# Reset simple bones
	if head_bone:
		head_bone.rotation = Vector3.ZERO
	if torso_bone:
		torso_bone.rotation = Vector3.ZERO
	
	# Reset arm poses
	set_arm_pose("left", "idle")
	set_arm_pose("right", "idle")
	
	# Reset leg poses
	set_leg_pose("left", "idle")
	set_leg_pose("right", "idle")
	
	Logger.info("PAWN", "✅ All poses reset to neutral")

func get_simple_bone(bone_name: String) -> Node3D:
	"""Get simple bone (Node3D) by name"""
	var bone = get_bone(bone_name)
	if bone and not bone is Skeleton3D:
		return bone
	return null

func get_skeleton_bone(bone_name: String) -> Skeleton3D:
	"""Get skeleton bone (Skeleton3D) by name"""
	var bone = get_bone(bone_name)
	if bone and bone is Skeleton3D:
		return bone as Skeleton3D
	return null

func get_bone_rotation(bone_name: String) -> Vector3:
	"""Get current rotation of bone"""
	var bone = get_bone(bone_name)
	if bone:
		return bone.rotation
	return Vector3.ZERO

func reset_bone_rotation(bone_name: String):
	"""Reset bone rotation to zero"""
	set_simple_bone_rotation(bone_name, Vector3.ZERO)

func reset_all_bones():
	"""Reset all bones to default rotation"""
	for bone_name in bones.keys():
		reset_bone_rotation(bone_name)
	Logger.info("PAWN", "Reset all bones to default rotation") 
