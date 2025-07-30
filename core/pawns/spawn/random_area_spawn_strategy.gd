extends SpawnStrategy
class_name RandomAreaSpawnStrategy

@export_group("Random Area Settings")
@export var area_center: Vector3 = Vector3.ZERO  # Center of spawn area
@export var area_size: Vector3 = Vector3(100, 0, 100)  # Size of spawn area
@export var use_world_center: bool = true  # Use world center as area center
@export var area_radius: float = 50.0  # Alternative: circular area radius

func get_spawn_position(world: Node3D, world_generator = null) -> Vector3:
	"""Get random spawn position within area"""
	var center = area_center
	
	if use_world_center and world_generator and world_generator.has_method("get_world_center"):
		center = world_generator.get_world_center()
	
	var random_position: Vector3
	
	if area_radius > 0:
		# Circular area
		var angle = randf() * TAU
		var radius = randf() * area_radius
		random_position = center + Vector3(cos(angle) * radius, 0, sin(angle) * radius)
	else:
		# Rectangular area
		var half_size = area_size / 2
		random_position = center + Vector3(
			randf_range(-half_size.x, half_size.x),
			0,
			randf_range(-half_size.z, half_size.z)
		)
	
	# Add height offset
	random_position.y += spawn_height_offset
	
	Logger.debug("PAWN", "Random area spawn position: " + str(random_position))
	return random_position 