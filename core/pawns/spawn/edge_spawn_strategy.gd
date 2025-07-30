extends SpawnStrategy
class_name EdgeSpawnStrategy

@export_group("Edge Spawn Settings")
@export var distance_from_edge: float = 10.0  # Distance from world edge
@export var edge_side: String = "random"  # "north", "south", "east", "west", "random"
@export var use_circular_edge: bool = false  # Use circular edge instead of rectangular

func get_spawn_position(world: Node3D, world_generator = null) -> Vector3:
	"""Get spawn position at world edge"""
	var world_bounds = AABB()
	
	if world_generator and world_generator.has_method("get_world_bounds"):
		world_bounds = world_generator.get_world_bounds()
	else:
		# Fallback bounds
		world_bounds = AABB(Vector3(-1000, 0, -1000), Vector3(2000, 100, 2000))
	
	var edge_position: Vector3
	var side = edge_side
	
	if side == "random":
		var sides = ["north", "south", "east", "west"]
		side = sides[randi() % sides.size()]
	
	if use_circular_edge:
		# Circular edge spawn
		var world_center = (world_bounds.position + world_bounds.end) / 2
		var world_radius = max(world_bounds.size.x, world_bounds.size.z) / 2
		var spawn_radius = world_radius - distance_from_edge
		
		var angle = randf() * TAU
		edge_position = world_center + Vector3(cos(angle) * spawn_radius, 0, sin(angle) * spawn_radius)
	else:
		# Rectangular edge spawn
		var world_size = world_bounds.size
		var world_center = (world_bounds.position + world_bounds.end) / 2
		
		match side:
			"north":
				edge_position = Vector3(
					randf_range(world_center.x - world_size.x/2 + distance_from_edge, 
							   world_center.x + world_size.x/2 - distance_from_edge),
					0,
					world_center.z - world_size.z/2 + distance_from_edge
				)
			"south":
				edge_position = Vector3(
					randf_range(world_center.x - world_size.x/2 + distance_from_edge, 
							   world_center.x + world_size.x/2 - distance_from_edge),
					0,
					world_center.z + world_size.z/2 - distance_from_edge
				)
			"east":
				edge_position = Vector3(
					world_center.x + world_size.x/2 - distance_from_edge,
					0,
					randf_range(world_center.z - world_size.z/2 + distance_from_edge, 
							   world_center.z + world_size.z/2 - distance_from_edge)
				)
			"west":
				edge_position = Vector3(
					world_center.x - world_size.x/2 + distance_from_edge,
					0,
					randf_range(world_center.z - world_size.z/2 + distance_from_edge, 
							   world_center.z + world_size.z/2 - distance_from_edge)
				)
	
	# Add height offset
	edge_position.y += spawn_height_offset
	
	Logger.debug("PAWN", "Edge spawn position (" + side + "): " + str(edge_position))
	return edge_position 