class_name OccupancyManager
extends RefCounted

## Manager that checks if an object can be placed

var terrain_grid = null  ## Reference to TerrainGrid
var build_grid = null    ## Reference to BuildGrid

## Check masks
enum CheckMask {
	TERRAIN_ONLY,      ## Only terrain check
	STRUCTURE_ONLY,    ## Only structure check
	DEFAULT,           ## Full check
	ALLOW_CEILING,     ## Allow placement under ceiling
	IGNORE_STRUCTURES, ## Ignore existing structures
	IGNORE_TERRAIN     ## Ignore terrain
}

## Initialize manager
func initialize(terrain_grid_instance: Object, build_grid_instance: Object):
	terrain_grid = terrain_grid_instance
	build_grid = build_grid_instance

## Checks if an object can be placed
func is_space_free(position: Vector3i, size: Vector3i, check_mask: CheckMask = CheckMask.DEFAULT) -> bool:
	match check_mask:
		CheckMask.TERRAIN_ONLY:
			return _check_terrain_only(position, size)
		CheckMask.STRUCTURE_ONLY:
			return _check_structures_only(position, size)
		CheckMask.ALLOW_CEILING:
			return _check_with_ceiling_allowed(position, size)
		CheckMask.IGNORE_STRUCTURES:
			return _check_ignore_structures(position, size)
		CheckMask.IGNORE_TERRAIN:
			return _check_ignore_terrain(position, size)
		_:
			return _check_default(position, size)

## Terrain only check
func _check_terrain_only(position: Vector3i, size: Vector3i) -> bool:
	if terrain_grid == null:
		return true
	
	for x in range(position.x, position.x + size.x):
		for y in range(position.y, position.y + size.y):
			for z in range(position.z, position.z + size.z):
				var check_pos = Vector3i(x, y, z)
				if not terrain_grid.is_position_suitable(check_pos):
					return false
	
	return true

## Structure only check
func _check_structures_only(position: Vector3i, size: Vector3i) -> bool:
	if build_grid == null:
		return true
	
	for x in range(position.x, position.x + size.x):
		for y in range(position.y, position.y + size.y):
			for z in range(position.z, position.z + size.z):
				var check_pos = Vector3i(x, y, z)
				if build_grid.has_object_at(check_pos):
					return false
	
	return true

## Check with ceiling allowed
func _check_with_ceiling_allowed(position: Vector3i, size: Vector3i) -> bool:
	if terrain_grid == null:
		return true
	
	for x in range(position.x, position.x + size.x):
		for y in range(position.y, position.y + size.y):
			for z in range(position.z, position.z + size.z):
				var check_pos = Vector3i(x, y, z)
				if not terrain_grid.is_position_suitable_with_ceiling(check_pos):
					return false
	
	return true

## Check with structures ignored
func _check_ignore_structures(position: Vector3i, size: Vector3i) -> bool:
	return _check_terrain_only(position, size)

## Check with terrain ignored
func _check_ignore_terrain(position: Vector3i, size: Vector3i) -> bool:
	return _check_structures_only(position, size)

## Default check
func _check_default(position: Vector3i, size: Vector3i) -> bool:
	return _check_terrain_only(position, size) and _check_structures_only(position, size)

## Checks that position is suitable for terrain
func _is_terrain_position_suitable(position: Vector3i) -> bool:
	if terrain_grid == null:
		return true
	
	return terrain_grid.is_position_suitable(position)

## Checks position with ceiling consideration
func _is_position_suitable_with_ceiling(position: Vector3i) -> bool:
	if terrain_grid == null:
		return true
	
	return terrain_grid.is_position_suitable_with_ceiling(position)

## Checks if object can be placed considering neighboring objects
func _check_neighbor_requirements(position: Vector3i, size: Vector3i) -> bool:
	# This is a placeholder for neighbor requirement logic
	# In a real implementation, you would check if the object needs specific neighbors
	return true

## Checks for required neighbor
func _has_required_neighbor(position: Vector3i, required_neighbor_type: String) -> bool:
	if build_grid == null:
		return false
	
	var neighbor_positions = _get_neighbor_positions(position)
	for neighbor_pos in neighbor_positions:
		var neighbor_object = build_grid.get_object(neighbor_pos)
		if neighbor_object and neighbor_object.object_id == required_neighbor_type:
			return true
	
	return false

## Returns neighboring cell positions
func _get_neighbor_positions(position: Vector3i) -> Array[Vector3i]:
	var neighbors: Array[Vector3i] = []
	
	# Add all 6 neighboring positions (up, down, left, right, front, back)
	neighbors.append(position + Vector3i(0, 1, 0))   # Up
	neighbors.append(position + Vector3i(0, -1, 0))  # Down
	neighbors.append(position + Vector3i(-1, 0, 0))  # Left
	neighbors.append(position + Vector3i(1, 0, 0))   # Right
	neighbors.append(position + Vector3i(0, 0, -1))  # Front
	neighbors.append(position + Vector3i(0, 0, 1))   # Back
	
	return neighbors

## Checks if there is enough space for object with margin
func _has_sufficient_space(position: Vector3i, size: Vector3i, margin: int = 1) -> bool:
	var expanded_size = size + Vector3i(margin * 2, margin * 2, margin * 2)
	var expanded_position = position - Vector3i(margin, margin, margin)
	
	return is_space_free(expanded_position, expanded_size) 