extends SpawnStrategy
class_name CenterSpawnStrategy

@export_group("Center Spawn Settings")
@export var center_offset: Vector3 = Vector3.ZERO  # Offset from world center
@export var use_world_center: bool = true  # Use world center or custom position

func get_spawn_position(world: Node3D, world_generator = null) -> Vector3:
	"""Get spawn position at world center"""
	var center_position = Vector3.ZERO
	
	if use_world_center and world_generator and world_generator.has_method("get_world_center"):
		center_position = world_generator.get_world_center()
	elif world_generator and world_generator.has_method("get_world_bounds"):
		var bounds = world_generator.get_world_bounds()
		center_position = (bounds.position + bounds.end) / 2
	else:
		# Fallback to origin
		center_position = Vector3.ZERO
	
	var spawn_position = center_position + center_offset
	
	# Add height offset
	spawn_position.y += spawn_height_offset
	
	Logger.debug("PAWN", "Center spawn position: " + str(spawn_position))
	return spawn_position 