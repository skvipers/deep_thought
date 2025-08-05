class_name BuildSystemManager
extends RefCounted

## Main build system manager

var build_grid: BuildGrid
var occupancy_manager: OccupancyManager
var build_factory: BuildObjectFactory
var priority_integration: BuildPriorityIntegration
var tick_integration: BuildTickIntegration
var current_ghost: GhostBuildObject
var game_node: Node
var ghost_valid_material: Material
var ghost_invalid_material: Material
var last_ghost_position: Vector3 = Vector3.ZERO  # For interpolation

## Signals
signal object_placed(object: BuildObject, position: Vector3i)
signal object_removed(object: BuildObject, position: Vector3i)
signal build_completed(object: BuildObject)
signal interaction_performed(object: InteractableObject, actor: Object)

## System initialization
func initialize(grid_size: Vector3i = Vector3i(100, 10, 100), build_factory_instance: BuildObjectFactory = null, game_reference: Node = null):
	# Create system components
	build_grid = BuildGrid.new()
	build_grid.set_grid_size(grid_size)
	
	occupancy_manager = OccupancyManager.new()
	
	# Use provided factory or create new one
	if build_factory_instance:
		build_factory = build_factory_instance
	else:
		build_factory = BuildObjectFactory.new()
		# Warn that factory is not configured
		push_warning("BuildSystemManager: Using default BuildObjectFactory without paths")
	
	# Save reference to Game
	game_node = game_reference
	
	priority_integration = BuildPriorityIntegration.new()
	tick_integration = BuildTickIntegration.new()
	
	# Initialize components (only if factory wasn't initialized before)
	if not build_factory._is_initialized:
		build_factory.initialize()
	priority_integration.initialize(null, build_grid)  # priority_system will be set later
	tick_integration.initialize(null, build_grid)     # tick_manager will be set later
	
	# Connect signals
	build_grid.object_placed.connect(_on_object_placed)
	build_grid.object_removed.connect(_on_object_removed)

## Sets references to other systems
func set_system_references(priority_system: Object, tick_manager: Object, terrain_grid: Object):
	priority_integration.initialize(priority_system, build_grid)
	tick_integration.initialize(tick_manager, build_grid)
	occupancy_manager.initialize(terrain_grid, build_grid)

## Creates and places an object
func create_and_place_object(object_id: String, position: Vector3i) -> BuildObject:
	var build_object = build_factory.create_build_object(object_id)
	if build_object == null:
		return null
	
	# Check placement possibility
	if not occupancy_manager.is_space_free(position, build_object.size):
		return null
	
	# Place object
	if build_grid.place_object(position, build_object):
		return build_object
	
	return null

## Creates an interactive object
func create_interactable_object(object_id: String, position: Vector3i) -> InteractableObject:
	var build_object = create_and_place_object(object_id, position)
	if build_object is InteractableObject:
		return build_object as InteractableObject
	return null

## Removes an object
func remove_object(position: Vector3i) -> bool:
	return build_grid.erase_object(position)

## Gets object at position
func get_object_at(position: Vector3i) -> BuildObject:
	return build_grid.get_object(position)

## Places object at specified position
func place_object(object_id: String, position: Vector3) -> bool:
	Logger.info("BUILD", "Placing object: " + object_id + " at position: " + str(position))
	
	var build_object = build_factory.create_build_object(object_id)
	if build_object == null:
		Logger.error("BUILD", "Failed to create build object: " + object_id)
		return false
	
	# Convert Vector3 to Vector3i for compatibility
	var position_i = Vector3i(position.x, position.y, position.z)
	var size_i = Vector3i(build_object.size.x, build_object.size.y, build_object.size.z)
	
	# Check if object can be placed
	if not occupancy_manager.is_space_free(position_i, size_i):
		Logger.warn("BUILD", "Space not free for object: " + object_id + " at position: " + str(position))
		return false
	
	# Place object in grid
	var success = build_grid.place_object(position_i, build_object)
	if success:
		Logger.info("BUILD", "Object placed successfully: " + object_id)
		return true
	else:
		Logger.error("BUILD", "Failed to place object in grid: " + object_id)
		return false

## Checks if object can be placed at specified position
func can_place_object(object_id: String, position: Vector3) -> bool:
	var build_object = build_factory.create_build_object(object_id)
	if build_object == null:
		return false
	
	# Convert Vector3 to Vector3i for compatibility
	var position_i = Vector3i(position.x, position.y, position.z)
	var size_i = Vector3i(build_object.size.x, build_object.size.y, build_object.size.z)
	
	return occupancy_manager.is_space_free(position_i, size_i)

## Creates a build task
func create_build_task(builder: Object, object_id: String, position: Vector3i) -> Object:
	var build_object = build_factory.create_build_object(object_id)
	if build_object == null:
		return null
	
	return priority_integration.create_build_task(builder, build_object, position)

## Creates an interaction task
func create_interaction_task(actor: Object, position: Vector3i) -> Object:
	var object = get_object_at(position)
	if object is InteractableObject:
		return priority_integration.create_interaction_task(actor, object)
	return null

## Performs interaction
func perform_interaction(actor: Object, position: Vector3i) -> bool:
	var object = get_object_at(position)
	if object is InteractableObject:
		var success = object.interact(actor)
		if success:
			interaction_performed.emit(object, actor)
		return success
	return false

## Updates the system
func update(delta: float):
	# Update all objects
	var all_objects = build_grid.get_all_objects()
	for object in all_objects:
		if object is InteractableObject:
			object.update(delta)
	
	# Update priorities
	priority_integration.update_object_priorities()

## Gets system statistics
func get_statistics() -> Dictionary:
	var stats = {
		"total_objects": 0,
		"build_objects": 0,
		"interactable_objects": 0,
		"completed_builds": 0,
		"in_progress_builds": 0
	}
	
	var all_objects = build_grid.get_all_objects()
	stats["total_objects"] = all_objects.size()
	
	for object in all_objects:
		if object is BuildObject:
			stats["build_objects"] += 1
			
			if object.is_built:
				stats["completed_builds"] += 1
			else:
				stats["in_progress_builds"] += 1
		
		if object is InteractableObject:
			stats["interactable_objects"] += 1
	
	return stats

## Gets objects by category
func get_objects_by_category(category: String) -> Array[BuildObject]:
	var result: Array[BuildObject] = []
	var all_objects = build_grid.get_all_objects()
	
	for object in all_objects:
		if object.has_method("get_category") and object.get_category() == category:
			result.append(object)
	
	return result

## Gets objects by tag
func get_objects_by_tag(tag: String) -> Array[BuildObject]:
	var result: Array[BuildObject] = []
	var all_objects = build_grid.get_all_objects()
	
	for object in all_objects:
		if tag in object.tags:
			result.append(object)
	
	return result

## Clears entire system
func clear_system():
	build_grid.clear_grid()
	priority_integration = null
	tick_integration = null

## Signal handlers
func _on_object_placed(position: Vector3i, object: BuildObject):
	object_placed.emit(object, position)
	
	# Register object for ticking
	if tick_integration != null:
		tick_integration.register_object_for_ticking(object)

func _on_object_removed(position: Vector3i, object: BuildObject):
	object_removed.emit(object, position)
	
	# Unregister object
	if tick_integration != null:
		tick_integration.unregister_object_from_ticking(object)

## Saves system state
func save_system_state() -> Dictionary:
	var state = {
		"grid_size": build_grid.grid_size,
		"objects": []
	}
	
	var all_objects = build_grid.get_all_objects()
	for object in all_objects:
		var object_state = {
			"id": object.object_id,
			"position": object.origin,
			"rotation": object.rotation,
			"build_progress": object.build_progress,
			"is_built": object.is_built
		}
		state["objects"].append(object_state)
	
	return state

## Loads system state
func load_system_state(state: Dictionary):
	clear_system()
	
	build_grid.set_grid_size(state.get("grid_size", Vector3i(100, 10, 100)))
	
	for object_state in state.get("objects", []):
		var object = build_factory.create_build_object(object_state["id"])
		if object != null:
			object.origin = object_state["position"]
			object.rotation = object_state["rotation"]
			object.build_progress = object_state["build_progress"]
			object.is_built = object_state["is_built"]
			
			build_grid.place_object(object_state["position"], object)

## Ghost methods

## Creates ghost for specified object
func create_ghost(object_id: String) -> GhostBuildObject:
	Logger.info("BUILD", "Creating ghost for object: " + object_id)
	
	# Remove previous ghost if exists
	remove_current_ghost()
	
	# Create BuildObject for ghost
	var build_object = build_factory.create_build_object(object_id)
	if build_object == null:
		Logger.error("BUILD", "Failed to create build object for: " + object_id)
		return null
	
	Logger.debug("BUILD", "Build object created: " + build_object.object_id + ", size: " + str(build_object.size))
	
	# Create new ghost
	var ghost = GhostBuildObject.new()
	ghost.initialize_from_object(build_object, ghost_valid_material, ghost_invalid_material)
	
	Logger.debug("BUILD", "Ghost created, adding to scene")
	
	# Add to scene
	if game_node:
		game_node.add_child(ghost)
		Logger.debug("BUILD", "Ghost added to game_node: " + str(game_node.name))
	else:
		Logger.error("BUILD", "No game_node to add ghost to")
		return null
	
	# Show ghost
	ghost.show_ghost()
	Logger.debug("BUILD", "Ghost show_ghost() called")
	
	# Set current ghost
	current_ghost = ghost
	
	# Initialize position for interpolation
	last_ghost_position = Vector3.ZERO
	
	Logger.info("BUILD", "Ghost creation completed successfully")
	
	# Check ghost state
	if current_ghost:
		current_ghost.check_ghost_state()
	
	return ghost

## Updates ghost position
func update_ghost_position(position: Vector3) -> Vector3i:
	if current_ghost != null:
		# Clamp mouse position for safety, can be removed if not needed
		position.x = clamp(position.x, -500, 500)
		position.z = clamp(position.z, -500, 500)
		
		# Snap the raw mouse position to the grid to find the target COLUMN
		var snapped_grid_pos = build_grid.snap_to_grid(position)
		
		# Clamp the position to the grid boundaries
		var grid_origin = build_grid.origin
		var grid_size = build_grid.get_grid_size()
		snapped_grid_pos.x = clamp(snapped_grid_pos.x, grid_origin.x, grid_origin.x + grid_size.x - 1)
		snapped_grid_pos.y = clamp(snapped_grid_pos.y, grid_origin.y, grid_origin.y + grid_size.y - 1)
		snapped_grid_pos.z = clamp(snapped_grid_pos.z, grid_origin.z, grid_origin.z + grid_size.z - 1)
		
		# Get the world position for the corner of that grid cell
		var world_pos = build_grid.grid_to_world(snapped_grid_pos)
		
		# Find the terrain height at the center of the cell
		world_pos.y = _get_terrain_height_at(world_pos.x + 0.5, world_pos.z + 0.5)
		
		# Adjust the ghost to sit on top of the terrain, centered in the cell
		world_pos += Vector3(0.5, current_ghost.get_ghost_size().y / 2.0, 0.5)
		
		# Tell the ghost where to move smoothly
		current_ghost.set_ghost_position(world_pos)
		
		# Now, determine the actual grid cell the ghost's base occupies
		# This is simply the snapped grid position but with the correct height
		var actual_grid_pos = build_grid.snap_to_grid(world_pos - Vector3(0.5, current_ghost.get_ghost_size().y, 0.5))

		# Check if this actual position is valid for building
		var is_valid = is_current_ghost_valid(actual_grid_pos)
		current_ghost.update_validity(is_valid)
		
		return actual_grid_pos
	else:
		Logger.warn("BUILD", "No current ghost to update")
		return Vector3i.ZERO

## Updates ghost rotation
func update_ghost_rotation(rotation: float):
	if current_ghost != null:
		Logger.debug("BUILD", "Updating ghost rotation to: " + str(rotation))
		current_ghost.set_ghost_rotation(rotation)
	else:
		Logger.warn("BUILD", "No current ghost to rotate")

## Checks validity of current ghost
func is_current_ghost_valid(snapped_grid_pos: Vector3i) -> bool:
	if current_ghost == null:
		Logger.debug("BUILD", "No current ghost")
		return false
	
	var ghost_size = current_ghost.get_ghost_size()
	
	# Validity check is now simpler. Main logic is in OccupancyManager.
	var ghost_size_i = Vector3i(ghost_size.x, ghost_size.y, ghost_size.z)
	
	var is_valid = occupancy_manager.is_space_free(snapped_grid_pos, Vector3i(ghost_size.x, ghost_size.y, ghost_size.z))
	
	Logger.debug("BUILD", "Ghost validity check at %s, size %s. Is valid: %s" % [snapped_grid_pos, ghost_size, is_valid])
	
	return is_valid

## Places object at ghost position
func place_object_at_ghost_position() -> BuildObject:
	if current_ghost == null:
		return null
	
	var ghost_pos = current_ghost.get_ghost_position()
	var snapped_pos = build_grid.snap_to_grid(ghost_pos)
	
	if not is_current_ghost_valid(snapped_pos):
		return null
	
	var object_id = current_ghost.get_object_id()
	
	Logger.info("BUILD", "Placing object at ghost position: " + str(ghost_pos))
	
	var grid_world_pos = build_grid.grid_to_world(snapped_pos)
	
	# Set terrain height for final position
	var terrain_height = _get_terrain_height_at(grid_world_pos.x, grid_world_pos.z)
	if terrain_height > 0:
		grid_world_pos.y = terrain_height
	
	Logger.info("BUILD", "Snapped position for placement: " + str(snapped_pos) + ", grid world pos: " + str(grid_world_pos))
	
	var placed_object = create_and_place_object(object_id, Vector3i(grid_world_pos))
	if placed_object != null:
		# Apply ghost rotation to placed object
		placed_object.rotation.y = deg_to_rad(current_ghost.get_ghost_rotation())
		Logger.info("BUILD", "Object placed successfully at grid position: " + str(snapped_pos))
	else:
		Logger.error("BUILD", "Failed to place object")
	
	return placed_object

## Removes current ghost
func remove_current_ghost():
	if current_ghost != null:
		Logger.info("BUILD", "Removing ghost")
		current_ghost.queue_free()
		current_ghost = null
		last_ghost_position = Vector3.ZERO  # Reset interpolation position
	else:
		Logger.debug("BUILD", "No ghost to remove") 

## Gets terrain height at specified point through game_node
func _get_terrain_height_at(x: float, z: float) -> float:
	if game_node and game_node.has_method("_get_terrain_height_at"):
		return game_node._get_terrain_height_at(x, z)
	
	Logger.warn("BUILD", "Cannot get terrain height, game_node not available. Returning 0.")
	return 0.0
