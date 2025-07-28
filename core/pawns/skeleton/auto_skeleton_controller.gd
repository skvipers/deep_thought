extends Node3D
class_name AutoSkeletonController

# Automatic controller for working with existing skeleton structure

const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@export var skeleton_root: Node3D  # Skeleton root (Skeleton)

# Automatically found nodes
var head_bone: Node3D
var torso_bone: Node3D
var left_arm_skeleton: Skeleton3D
var right_arm_skeleton: Skeleton3D
var left_leg_skeleton: Skeleton3D
var right_leg_skeleton: Skeleton3D

var head_mesh: MeshInstance3D
var torso_mesh: MeshInstance3D
var left_arm_mesh: MeshInstance3D
var right_arm_mesh: MeshInstance3D
var left_leg_mesh: MeshInstance3D
var right_leg_mesh: MeshInstance3D

func _ready():
	_auto_find_nodes()
	setup_meshes()

func _auto_find_nodes():
	"""Automatically finds all nodes in skeleton structure"""
	if not skeleton_root:
		Logger.error("PAWN", "skeleton_root not set!")
		return
	
	Logger.info("PAWN", "Starting automatic node search...")
	
	# Automatically find simple bones
	head_bone = _find_node_by_name(skeleton_root, "head")
	torso_bone = _find_node_by_name(skeleton_root, "torso")
	
	# Automatically find limb skeletons
	left_arm_skeleton = _find_skeleton_by_name(skeleton_root, "left_arm", "ArmSkeleton")
	right_arm_skeleton = _find_skeleton_by_name(skeleton_root, "right_arm", "ArmSkeleton")
	left_leg_skeleton = _find_skeleton_by_name(skeleton_root, "left_leg", "LegSkeleton")
	right_leg_skeleton = _find_skeleton_by_name(skeleton_root, "right_leg", "LegSkeleton")
	
	# Automatically find meshes
	head_mesh = _find_mesh_by_name(skeleton_root, "head", "head_mesh")
	torso_mesh = _find_mesh_by_name(skeleton_root, "torso", "torso_mesh")
	left_arm_mesh = _find_mesh_by_name(skeleton_root, "left_arm/ArmSkeleton", "left_arm_mesh")
	right_arm_mesh = _find_mesh_by_name(skeleton_root, "right_arm/ArmSkeleton", "right_arm_mesh")
	left_leg_mesh = _find_mesh_by_name(skeleton_root, "left_leg/LegSkeleton", "left_leg_mesh")
	right_leg_mesh = _find_mesh_by_name(skeleton_root, "right_leg/LegSkeleton", "right_leg_mesh")
	
	Logger.info("PAWN", "Node search completed!")
	_print_found_nodes()

func _find_node_by_name(parent: Node, name: String) -> Node3D:
	"""Find node by name"""
	var node = parent.get_node_or_null(name)
	if node:
		Logger.debug("PAWN", "Found node: " + name)
	else:
		Logger.warn("PAWN", "Node not found: " + name)
	return node

func _find_skeleton_by_name(parent: Node, bone_name: String, skeleton_name: String) -> Skeleton3D:
	"""Find skeleton by name"""
	var path = bone_name + "/" + skeleton_name
	var node = parent.get_node_or_null(path)
	if node and node is Skeleton3D:
		Logger.debug("PAWN", "Found skeleton: " + path)
		return node
	else:
		Logger.warn("PAWN", "Skeleton not found: " + path)
		return null

func _find_mesh_by_name(parent: Node, path: String, mesh_name: String) -> MeshInstance3D:
	"""Find mesh by name"""
	var full_path = path + "/" + mesh_name
	var node = parent.get_node_or_null(full_path)
	if node and node is MeshInstance3D:
		Logger.debug("PAWN", "Found mesh: " + full_path)
		return node
	else:
		Logger.warn("PAWN", "Mesh not found: " + full_path)
		return null

func _print_found_nodes():
	"""Print information about found nodes"""
	Logger.info("PAWN", "=== Found Nodes ===")
	Logger.info("PAWN", "Simple bones:")
	Logger.info("PAWN", "- Head: " + str(head_bone != null))
	Logger.info("PAWN", "- Torso: " + str(torso_bone != null))
	Logger.info("PAWN", "Skeletons:")
	Logger.info("PAWN", "- Left arm: " + str(left_arm_skeleton != null))
	Logger.info("PAWN", "- Right arm: " + str(right_arm_skeleton != null))
	Logger.info("PAWN", "- Left leg: " + str(left_leg_skeleton != null))
	Logger.info("PAWN", "- Right leg: " + str(right_leg_skeleton != null))
	Logger.info("PAWN", "Meshes:")
	Logger.info("PAWN", "- Head: " + str(head_mesh != null))
	Logger.info("PAWN", "- Torso: " + str(torso_mesh != null))

func setup_meshes():
	"""Sets up meshes"""
	_show_mesh(head_mesh, "head")
	_show_mesh(torso_mesh, "torso")
	_show_mesh(left_arm_mesh, "left_arm")
	_show_mesh(right_arm_mesh, "right_arm")
	_show_mesh(left_leg_mesh, "left_leg")
	_show_mesh(right_leg_mesh, "right_leg")
	
	# Link meshes to skeletons
	_link_mesh_to_skeleton(left_arm_mesh, left_arm_skeleton, "left_arm")
	_link_mesh_to_skeleton(right_arm_mesh, right_arm_skeleton, "right_arm")
	_link_mesh_to_skeleton(left_leg_mesh, left_leg_skeleton, "left_leg")
	_link_mesh_to_skeleton(right_leg_mesh, right_leg_skeleton, "right_leg")

func _show_mesh(mesh: MeshInstance3D, part_name: String):
	"""Shows mesh"""
	if mesh:
		mesh.visible = true
		Logger.debug("PAWN", "Mesh " + part_name + " shown")
	else:
		Logger.warn("PAWN", "Mesh " + part_name + " not found")

func _link_mesh_to_skeleton(mesh: MeshInstance3D, skeleton: Skeleton3D, part_name: String):
	"""Links mesh to skeleton"""
	if mesh and skeleton:
		mesh.skeleton = skeleton.get_path()
		Logger.debug("PAWN", "Mesh " + part_name + " linked to skeleton")
	else:
		Logger.warn("PAWN", "Could not link mesh " + part_name + " to skeleton")

# Control simple bones
func rotate_head(rotation: Vector3):
	"""Rotates head"""
	if head_bone:
		head_bone.rotation = rotation
		Logger.debug("PAWN", "Head rotated: " + str(rotation))

func rotate_torso(rotation: Vector3):
	"""Rotates torso"""
	if torso_bone:
		torso_bone.rotation = rotation
		Logger.debug("PAWN", "Torso rotated: " + str(rotation))

# Control limb skeletons
func set_arm_pose(side: String, pose_name: String):
	"""Sets arm pose"""
	var skeleton = _get_arm_skeleton(side)
	if not skeleton:
		Logger.warn("PAWN", "Skeleton for " + side + " arm not found")
		return
	
	match pose_name:
		"idle":
			_set_arm_idle_pose(skeleton, side)
		"raised":
			_set_arm_raised_pose(skeleton, side)
		"pointing":
			_set_arm_pointing_pose(skeleton, side)
		"bent":
			_set_arm_bent_pose(skeleton, side)

func set_leg_pose(side: String, pose_name: String):
	"""Sets leg pose"""
	var skeleton = _get_leg_skeleton(side)
	if not skeleton:
		Logger.warn("PAWN", "Skeleton for " + side + " leg not found")
		return
	
	match pose_name:
		"idle":
			_set_leg_idle_pose(skeleton, side)
		"walking":
			_set_leg_walking_pose(skeleton, side)
		"kicking":
			_set_leg_kicking_pose(skeleton, side)

func _get_arm_skeleton(side: String) -> Skeleton3D:
	"""Returns arm skeleton by side"""
	match side:
		"left":
			return left_arm_skeleton
		"right":
			return right_arm_skeleton
		_:
			return null

func _get_leg_skeleton(side: String) -> Skeleton3D:
	"""Returns leg skeleton by side"""
	match side:
		"left":
			return left_leg_skeleton
		"right":
			return right_leg_skeleton
		_:
			return null

# Arm poses
func _set_arm_idle_pose(skeleton: Skeleton3D, side: String):
	"""Sets idle pose for arm"""
	var shoulder_bone = skeleton.find_bone("Shoulder")
	var elbow_bone = skeleton.find_bone("Elbow")
	
	if shoulder_bone >= 0:
		var pose = skeleton.get_bone_pose(shoulder_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 0))
		skeleton.set_bone_pose(shoulder_bone, pose)
	
	if elbow_bone >= 0:
		var pose = skeleton.get_bone_pose(elbow_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 0))
		skeleton.set_bone_pose(elbow_bone, pose)
	
	Logger.debug("PAWN", "Idle pose set for " + side + " arm")

func _set_arm_raised_pose(skeleton: Skeleton3D, side: String):
	"""Sets raised arm"""
	var shoulder_bone = skeleton.find_bone("Shoulder")
	var elbow_bone = skeleton.find_bone("Elbow")
	
	if shoulder_bone >= 0:
		var pose = skeleton.get_bone_pose(shoulder_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 90))
		skeleton.set_bone_pose(shoulder_bone, pose)
	
	if elbow_bone >= 0:
		var pose = skeleton.get_bone_pose(elbow_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 0))
		skeleton.set_bone_pose(elbow_bone, pose)
	
	Logger.debug("PAWN", side + " arm raised")

func _set_arm_pointing_pose(skeleton: Skeleton3D, side: String):
	"""Sets pointing pose"""
	var shoulder_bone = skeleton.find_bone("Shoulder")
	var elbow_bone = skeleton.find_bone("Elbow")
	
	if shoulder_bone >= 0:
		var pose = skeleton.get_bone_pose(shoulder_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 45))
		skeleton.set_bone_pose(shoulder_bone, pose)
	
	if elbow_bone >= 0:
		var pose = skeleton.get_bone_pose(elbow_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 90))
		skeleton.set_bone_pose(elbow_bone, pose)
	
	Logger.debug("PAWN", side + " arm is pointing")

func _set_arm_bent_pose(skeleton: Skeleton3D, side: String):
	"""Sets bent arm"""
	var shoulder_bone = skeleton.find_bone("Shoulder")
	var elbow_bone = skeleton.find_bone("Elbow")
	
	if shoulder_bone >= 0:
		var pose = skeleton.get_bone_pose(shoulder_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 30))
		skeleton.set_bone_pose(shoulder_bone, pose)
	
	if elbow_bone >= 0:
		var pose = skeleton.get_bone_pose(elbow_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 120))
		skeleton.set_bone_pose(elbow_bone, pose)
	
	Logger.debug("PAWN", side + " arm bent")

# Leg poses
func _set_leg_idle_pose(skeleton: Skeleton3D, side: String):
	"""Sets idle pose for leg"""
	var hip_bone = skeleton.find_bone("Hip")
	var knee_bone = skeleton.find_bone("Knee")
	
	if hip_bone >= 0:
		var pose = skeleton.get_bone_pose(hip_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 0))
		skeleton.set_bone_pose(hip_bone, pose)
	
	if knee_bone >= 0:
		var pose = skeleton.get_bone_pose(knee_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 0))
		skeleton.set_bone_pose(knee_bone, pose)
	
	Logger.debug("PAWN", "Idle pose set for " + side + " leg")

func _set_leg_walking_pose(skeleton: Skeleton3D, side: String):
	"""Sets walking pose"""
	var hip_bone = skeleton.find_bone("Hip")
	var knee_bone = skeleton.find_bone("Knee")
	
	if hip_bone >= 0:
		var pose = skeleton.get_bone_pose(hip_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 30))
		skeleton.set_bone_pose(hip_bone, pose)
	
	if knee_bone >= 0:
		var pose = skeleton.get_bone_pose(knee_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 60))
		skeleton.set_bone_pose(knee_bone, pose)
	
	Logger.debug("PAWN", side + " leg in walking pose")

func _set_leg_kicking_pose(skeleton: Skeleton3D, side: String):
	"""Sets kicking pose"""
	var hip_bone = skeleton.find_bone("Hip")
	var knee_bone = skeleton.find_bone("Knee")
	
	if hip_bone >= 0:
		var pose = skeleton.get_bone_pose(hip_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 45))
		skeleton.set_bone_pose(hip_bone, pose)
	
	if knee_bone >= 0:
		var pose = skeleton.get_bone_pose(knee_bone)
		pose.basis = Basis.from_euler(Vector3(0, 0, 90))
		skeleton.set_bone_pose(knee_bone, pose)
	
	Logger.debug("PAWN", side + " leg in kicking pose")

# Input handling for testing
func _input(event):
	if event.is_action_pressed("ui_left"):
		set_arm_pose("left", "raised")
	elif event.is_action_pressed("ui_right"):
		set_arm_pose("right", "pointing")
	elif event.is_action_pressed("ui_up"):
		set_leg_pose("left", "walking")
	elif event.is_action_pressed("ui_down"):
		set_leg_pose("right", "kicking")
	elif event.is_action_pressed("ui_accept"):
		# Reset all poses
		set_arm_pose("left", "idle")
		set_arm_pose("right", "idle")
		set_leg_pose("left", "idle")
		set_leg_pose("right", "idle")
		rotate_head(Vector3.ZERO)
		rotate_torso(Vector3.ZERO)
		Logger.debug("PAWN", "All poses reset") 
