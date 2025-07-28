extends Resource
class_name AttachmentData

@export var part_name: String
@export var bone_name: String
@export var position: Vector3
@export var rotation: Vector3
@export var scale: Vector3 = Vector3.ONE

func _init(part: String = "", bone: String = "", attach_position: Vector3 = Vector3.ZERO, attach_rotation: Vector3 = Vector3.ZERO):
	part_name = part
	bone_name = bone
	position = attach_position
	rotation = attach_rotation

func get_transform() -> Transform3D:
	"""Returns attachment transform"""
	return Transform3D(Basis.from_euler(rotation).scaled(scale), position)

func set_transform(transform: Transform3D):
	"""Sets attachment transform"""
	position = transform.origin
	rotation = transform.basis.get_euler()
	scale = transform.basis.get_scale() 