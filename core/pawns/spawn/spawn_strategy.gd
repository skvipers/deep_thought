extends RefCounted
class_name SpawnStrategy

const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

# Spawn parameters
@export_group("Spawn Parameters")
@export var spawn_height_offset: float = 1.0  # Height above surface
@export var max_spawn_attempts: int = 10  # Max attempts to find valid position
@export var check_surface_validity: bool = true  # Check if surface is suitable

# Validation parameters
@export_group("Validation Parameters")
@export var min_surface_angle: float = 0.0  # Minimum surface angle (0 = flat)
@export var max_surface_angle: float = 45.0  # Maximum surface angle
@export var required_clearance: float = 1.0  # Required clearance around spawn point

func get_spawn_position(world: Node3D, world_generator = null) -> Vector3:
	"""Get spawn position based on strategy. Override in subclasses."""
	Logger.warn("PAWN", "❌ Base SpawnStrategy.get_spawn_position() called - override in subclass")
	return Vector3.ZERO

func validate_spawn_position(position: Vector3, world: Node3D, world_generator = null) -> bool:
	"""Validate if position is suitable for spawning"""
	if not check_surface_validity:
		return true
	
	# Check if position is within world bounds
	if world_generator and world_generator.has_method("is_position_in_bounds"):
		if not world_generator.is_position_in_bounds(position):
			Logger.debug("PAWN", "Position outside world bounds: " + str(position))
			return false
	
	# Check surface angle (if we have a way to get surface normal)
	var surface_normal = _get_surface_normal(position, world, world_generator)
	if surface_normal != Vector3.UP:
		var angle = rad_to_deg(acos(surface_normal.dot(Vector3.UP)))
		if angle < min_surface_angle or angle > max_surface_angle:
			Logger.debug("PAWN", "Surface angle unsuitable: " + str(angle) + " degrees")
			return false
	
	# Check clearance around spawn point
	if not _check_clearance(position, world):
		Logger.debug("PAWN", "Insufficient clearance at position: " + str(position))
		return false
	
	return true

func _get_surface_normal(position: Vector3, world: Node3D, world_generator = null) -> Vector3:
	"""Get surface normal at position. Override for specific world types."""
	# Default implementation - assume flat surface
	return Vector3.UP

func _check_clearance(position: Vector3, world: Node3D) -> bool:
	"""Check if there's sufficient clearance around spawn point"""
	# Simple raycast check for now
	var space_state = world.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = position + Vector3.UP * 10
	query.to = position + Vector3.DOWN * 10
	query.collision_mask = 1  # Adjust based on your collision layers
	
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return false
	
	# Check if there's enough space around
	for offset in [Vector3(required_clearance, 0, 0), Vector3(-required_clearance, 0, 0), 
				   Vector3(0, 0, required_clearance), Vector3(0, 0, -required_clearance)]:
		query.from = position + offset + Vector3.UP * 5
		query.to = position + offset + Vector3.DOWN * 5
		result = space_state.intersect_ray(query)
		if result.is_empty():
			return false
	
	return true

func find_valid_spawn_position(world: Node3D, world_generator = null) -> Vector3:
	"""Find a valid spawn position with multiple attempts"""
	for attempt in range(max_spawn_attempts):
		var position = get_spawn_position(world, world_generator)
		if validate_spawn_position(position, world, world_generator):
			Logger.debug("PAWN", "Found valid spawn position on attempt " + str(attempt + 1) + ": " + str(position))
			return position
		Logger.debug("PAWN", "Spawn attempt " + str(attempt + 1) + " failed")
	
	Logger.warn("PAWN", "❌ Failed to find valid spawn position after " + str(max_spawn_attempts) + " attempts")
	return get_spawn_position(world, world_generator)  # Return last attempt anyway

func get_spawn_transform(world: Node3D, world_generator = null) -> Transform3D:
	"""Get spawn transform with position and orientation"""
	var position = find_valid_spawn_position(world, world_generator)
	var transform = Transform3D()
	transform.origin = position
	
	# Orient based on surface normal
	var surface_normal = _get_surface_normal(position, world, world_generator)
	if surface_normal != Vector3.UP:
		var up_vector = Vector3.UP
		var rotation_axis = up_vector.cross(surface_normal).normalized()
		var rotation_angle = acos(up_vector.dot(surface_normal))
		transform.basis = transform.basis.rotated(rotation_axis, rotation_angle)
	
	return transform 