@tool
extends Resource
class_name UnifiedBoneData

enum BoneType {
	SIMPLE,    # Простые кости (Node3D)
	SKELETON   # Скелетные кости (Skeleton3D)
}

@export_group("Основные настройки")
@export var name: String
@export var bone_type: BoneType = BoneType.SIMPLE
@export var position: Vector3 = Vector3.ZERO
@export var rotation: Vector3 = Vector3.ZERO

@export_group("Пути к узлам")
@export var node_path: String = ""  # Path to the main node (Node3D or Skeleton3D)
@export var mesh_path: String = ""  # Path to the mesh

@export_group("Настройки костей")
@export var child_bones: Array[String] = []  # Names of child bones (только для SIMPLE типа)
@export var joint_names: Array[String] = []  # Names of bones within the skeleton (только для SKELETON типа)
@export var skeleton_path: String = ""  # Path to Skeleton3D (только для SKELETON типа)

func _init(bone_name: String = "", bone_type: BoneType = BoneType.SIMPLE):
	name = bone_name
	self.bone_type = bone_type

func is_simple() -> bool: 
	return bone_type == BoneType.SIMPLE

func is_skeleton() -> bool: 
	return bone_type == BoneType.SKELETON

func setup_simple_bone(bone_name: String, node_path: String, mesh_path: String, child_bones: Array[String] = []):
	"""Настройка простой кости"""
	name = bone_name
	bone_type = BoneType.SIMPLE
	self.node_path = node_path
	self.mesh_path = mesh_path
	self.child_bones = child_bones

func setup_skeleton_bone(bone_name: String, skeleton_path: String, mesh_path: String, joint_names: Array[String] = []):
	"""Настройка скелетной кости"""
	name = bone_name
	bone_type = BoneType.SKELETON
	node_path = skeleton_path
	self.skeleton_path = skeleton_path
	self.mesh_path = mesh_path
	self.joint_names = joint_names

func get_node(parent: Node) -> Node3D:
	"""Возвращает основной узел кости"""
	if node_path.is_empty(): 
		return parent.get_node_or_null(name)
	return parent.get_node_or_null(node_path)

func get_mesh(parent: Node) -> MeshInstance3D:
	"""Возвращает меш кости"""
	if mesh_path.is_empty():
		if bone_type == BoneType.SKELETON: 
			return parent.get_node_or_null(node_path + "/" + name + "_mesh")
		else: 
			return parent.get_node_or_null(name + "/" + name + "_mesh")
	return parent.get_node_or_null(mesh_path)

func get_skeleton(parent: Node) -> Skeleton3D:
	"""Возвращает скелет (только для skeleton типа)"""
	if bone_type == BoneType.SKELETON:
		if not skeleton_path.is_empty():
			return parent.get_node_or_null(skeleton_path) as Skeleton3D
		return get_node(parent) as Skeleton3D
	return null

func get_child_nodes(parent: Node) -> Array[Node3D]:
	"""Возвращает дочерние узлы (только для simple типа)"""
	var children: Array[Node3D] = []
	for child_name in child_bones:
		var child = parent.get_node_or_null(child_name)
		if child: 
			children.append(child)
	return children

func print_info():
	"""Выводит информацию о кости"""
	print("=== Кость: ", name, " ===")
	print("Тип: ", "simple" if bone_type == BoneType.SIMPLE else "skeleton")
	print("Позиция: ", position)
	print("Путь к узлу: ", node_path)
	print("Путь к мешу: ", mesh_path)
	if bone_type == BoneType.SIMPLE: 
		print("Дочерние кости: ", child_bones)
	elif bone_type == BoneType.SKELETON: 
		print("Путь к скелету: ", skeleton_path)
		print("Суставы: ", joint_names) 
