@tool
extends Resource
class_name UnifiedBoneData

const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

enum BoneType {
	SIMPLE,    # Simple bones (Node3D)
	SKELETON   # Skeletal bones (Skeleton3D)
}

@export_group("Basic Settings")
@export var name: String
@export var bone_type: BoneType = BoneType.SIMPLE
@export var position: Vector3 = Vector3.ZERO
@export var rotation: Vector3 = Vector3.ZERO

@export_group("Node Paths")
@export var node_path: String = ""  # Path to the main node (Node3D or Skeleton3D)
@export var mesh_path: String = ""  # Path to the mesh

@export_group("Bone Settings")
@export var child_bones: Array[String] = []  # Names of child bones (only for SIMPLE type)
@export var joint_names: Array[String] = []  # Names of bones within the skeleton (only for SKELETON type)
@export var skeleton_path: String = ""  # Path to Skeleton3D (only for SKELETON type)

func _init(bone_name: String = "", bone_type: BoneType = BoneType.SIMPLE):
	name = bone_name
	self.bone_type = bone_type

func is_simple() -> bool: 
	return bone_type == BoneType.SIMPLE

func is_skeleton() -> bool: 
	return bone_type == BoneType.SKELETON

func setup_simple_bone(bone_name: String, node_path: String, mesh_path: String, child_bones: Array[String] = []):
	"""Setup simple bone"""
	name = bone_name
	bone_type = BoneType.SIMPLE
	self.node_path = node_path
	self.mesh_path = mesh_path
	self.child_bones = child_bones

func setup_skeleton_bone(bone_name: String, skeleton_path: String, mesh_path: String, joint_names: Array[String] = []):
	"""Setup skeletal bone"""
	name = bone_name
	bone_type = BoneType.SKELETON
	node_path = skeleton_path
	self.skeleton_path = skeleton_path
	self.mesh_path = mesh_path
	self.joint_names = joint_names

func get_node(parent: Node) -> Node3D:
	"""Returns the main bone node"""
	if node_path.is_empty(): 
		return parent.get_node_or_null(name)
	return parent.get_node_or_null(node_path)

func get_mesh(parent: Node) -> MeshInstance3D:
	"""Returns the bone mesh"""
	if mesh_path.is_empty():
		if bone_type == BoneType.SKELETON: 
			return parent.get_node_or_null(node_path + "/" + name + "_mesh")
		else: 
			return parent.get_node_or_null(name + "/" + name + "_mesh")
	return parent.get_node_or_null(mesh_path)

func get_skeleton(parent: Node) -> Skeleton3D:
	"""Returns the skeleton (only for skeleton type)"""
	if bone_type == BoneType.SKELETON:
		if not skeleton_path.is_empty():
			return parent.get_node_or_null(skeleton_path) as Skeleton3D
		return get_node(parent) as Skeleton3D
	return null

func get_child_nodes(parent: Node) -> Array[Node3D]:
	"""Returns child nodes (only for simple type)"""
	var children: Array[Node3D] = []
	for child_name in child_bones:
		var child = parent.get_node_or_null(child_name)
		if child: 
			children.append(child)
	return children

func print_info():
	"""Prints bone information"""
	Logger.debug("PAWN", "=== Bone: " + name + " ===")
	Logger.debug("PAWN", "Type: " + ("simple" if bone_type == BoneType.SIMPLE else "skeleton"))
	Logger.debug("PAWN", "Position: " + str(position))
	Logger.debug("PAWN", "Node path: " + node_path)
	Logger.debug("PAWN", "Mesh path: " + mesh_path)
	if bone_type == BoneType.SIMPLE: 
		Logger.debug("PAWN", "Child bones: " + str(child_bones))
	elif bone_type == BoneType.SKELETON: 
		Logger.debug("PAWN", "Skeleton path: " + skeleton_path)
		Logger.debug("PAWN", "Joints: " + str(joint_names)) 
