extends Node3D
class_name StarDisplay
@export var star_config: StarConfig
@export var target_object: Node3D
@export var use_spot_light: bool = true  # Переключатель типа света
@onready var light := SpotLight3D.new() if use_spot_light else DirectionalLight3D.new()
@onready var mesh_instance := MeshInstance3D.new()

func _ready():
	add_child(light)
	add_child(mesh_instance)
	setup_light()
	setup_visual()

func setup_light():
	var star_pos = star_config.direction.normalized() * star_config.distance
	var target_pos = Vector3.ZERO
	if target_object:
		target_pos = target_object.global_position
	
	var light_direction = (star_pos - target_pos).normalized()
	
	light.global_position = star_pos
	light.look_at(star_pos + light_direction, Vector3.UP)
	
	light.light_color = star_config.light_color
	light.light_energy = star_config.intensity
	light.shadow_enabled = true

func setup_visual():
	var star_pos = star_config.direction.normalized() * star_config.distance
	
	var mesh := SphereMesh.new()
	mesh.radius = star_config.size
	mesh.height = star_config.size * 2
	mesh.radial_segments = 64
	mesh.rings = 32
	mesh_instance.mesh = mesh
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = star_config.light_color
	material.emission_energy = 3.0
	material.albedo_color = star_config.light_color
	# Делаем звезду источником света
	material.flags_unshaded = true
	mesh_instance.material_override = material
	mesh_instance.global_position = star_pos
