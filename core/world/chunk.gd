extends Node3D
class_name Chunk

const TAG := "Chunk"

@onready var renderer := $ChunkRenderer

var map_buffer: MapBuffer
var block_library: BlockLibrary
var chunk_position: Vector3i  # Stores chunk position
var chunk_size: Vector3i      # Stores chunk size

# Overlay states storage
var overlay_states: Dictionary = {} # Vector3i -> BlockOverlayState

func initialize(pos: Vector3i, size: Vector3i, buffer: MapBuffer, library: BlockLibrary) -> void:
	Logger.debug(TAG, "Initializing chunk at position: %s" % pos)
	position = Vector3(pos * size)
	chunk_position = pos
	chunk_size = size
	map_buffer = buffer
	block_library = library
	
	# Pass data to renderer
	renderer.buffer = map_buffer
	renderer.block_library = block_library
	renderer.chunk_size = size
	
	# Synchronize overlays with renderer
	renderer.overlay_states = overlay_states
	
	# Trigger mesh construction
	renderer.initialize_and_build()
	Logger.info(TAG, "Chunk initialized. Blocks in buffer: %d" % buffer.get_block_positions().size())

# Overlay management methods
func set_overlay(local_pos: Vector3i, overlay_state: BlockOverlayState):
	if not is_position_in_chunk(local_pos):
		Logger.warn(TAG, "Cannot set overlay outside chunk bounds: %s" % str(local_pos))
		return
	
	overlay_states[local_pos] = overlay_state
	if renderer:
		renderer.set_overlay(local_pos, overlay_state)

func get_overlay(local_pos: Vector3i) -> BlockOverlayState:
	return overlay_states.get(local_pos, null)

func remove_overlay(local_pos: Vector3i):
	overlay_states.erase(local_pos)
	if renderer:
		renderer.remove_overlay(local_pos)

# Position and coordinate methods
func get_chunk_position() -> Vector3i:
	return chunk_position

func get_world_position() -> Vector3i:
	return chunk_position * chunk_size

func get_chunk_size() -> Vector3i:
	return chunk_size

func world_to_local_position(world_pos: Vector3i) -> Vector3i:
	"""Converts world position to local chunk position"""
	return world_pos - (chunk_position * chunk_size)

func local_to_world_position(local_pos: Vector3i) -> Vector3i:
	"""Converts local position to world position"""
	return (chunk_position * chunk_size) + local_pos

func is_position_in_chunk(local_pos: Vector3i) -> bool:
	"""Checks if position is within chunk bounds"""
	return (local_pos.x >= 0 and local_pos.x < chunk_size.x and 
			local_pos.y >= 0 and local_pos.y < chunk_size.y and 
			local_pos.z >= 0 and local_pos.z < chunk_size.z)

# Block access methods
func get_block_at(local_pos: Vector3i) -> BlockType:
	"""Gets block type at local position in chunk"""
	if not is_position_in_chunk(local_pos):
		Logger.warn(TAG, "Position %s is outside chunk bounds" % str(local_pos))
		return null
	
	if not map_buffer:
		Logger.warn(TAG, "Map buffer is null")
		return null
	
	var block_id = map_buffer.get_block(local_pos)
	if block_id == -1:
		return null
	
	if not block_library:
		Logger.warn(TAG, "Block library is null")
		return null
	
	return block_library.get_block_by_id(block_id)

func has_block_at(local_pos: Vector3i) -> bool:
	"""Checks if there's a solid block at local position"""
	var block = get_block_at(local_pos)
	return block != null and block.is_solid

func get_block_id_at(local_pos: Vector3i) -> int:
	"""Gets block ID at local position"""
	if not is_position_in_chunk(local_pos) or not map_buffer:
		return -1
	return map_buffer.get_block(local_pos)

# Surface detection methods
func is_surface_block(local_pos: Vector3i) -> bool:
	"""Checks if block is a surface block (no block above)"""
	if not has_block_at(local_pos):
		return false
	
	var above_pos = local_pos + Vector3i(0, 1, 0)
	
	# If position is above chunk, consider no block exists
	if above_pos.y >= chunk_size.y:
		return true
	
	# Check if there's a block above
	return not has_block_at(above_pos)

func get_surface_blocks() -> Array[Vector3i]:
	"""Returns list of all surface blocks in chunk"""
	var surface_blocks: Array[Vector3i] = []
	
	for x in range(chunk_size.x):
		for z in range(chunk_size.z):
			# Find topmost block in column
			for y in range(chunk_size.y - 1, -1, -1):
				var local_pos = Vector3i(x, y, z)
				if has_block_at(local_pos):
					surface_blocks.append(local_pos)
					break  # Found top block in this column
	
	return surface_blocks

func get_blocks_suitable_for_overlay(overlay_type: int) -> Array[Vector3i]:
	"""Returns list of blocks suitable for specific overlay type"""
	var suitable_blocks: Array[Vector3i] = []
	
	var surface_blocks = get_surface_blocks()
	for local_pos in surface_blocks:
		var block = get_block_at(local_pos)
		# Note: BlockType needs to have can_have_overlay method or similar
		if block and block.allow_grass_overlay:  # Fallback check
			suitable_blocks.append(local_pos)
	
	return suitable_blocks

# Overlay statistics methods
func count_overlays() -> int:
	"""Counts total number of overlays in chunk"""
	return overlay_states.size()

func count_overlays_of_type(overlay_type: int) -> int:
	"""Counts number of overlays of specific type"""
	var count = 0
	for state in overlay_states.values():
		if state.has_overlay(overlay_type):
			count += 1
	return count

func clear_all_overlays():
	"""Clears all overlays in chunk"""
	overlay_states.clear()
	if renderer:
		renderer.overlay_states.clear()
		renderer.mark_for_rebuild()

# Chunk rebuild methods
func request_rebuild():
	if renderer:
		renderer.mark_for_rebuild()

func force_rebuild():
	"""Force rebuilds chunk mesh"""
	if renderer:
		renderer.force_rebuild()

func mark_for_rebuild():
	"""Marks chunk for rebuild (alias for request_rebuild)"""
	request_rebuild()

# Debug methods
func get_debug_info() -> Dictionary:
	"""Returns debug information about chunk"""
	var info = {
		"position": chunk_position,
		"size": chunk_size,
		"total_blocks": map_buffer.get_block_positions().size() if map_buffer else 0,
		"overlay_count": overlay_states.size(),
		"surface_blocks": get_surface_blocks().size()
	}
	
	# Count blocks by type
	var block_types = {}
	if map_buffer and block_library:
		for pos in map_buffer.get_block_positions():
			var block_id = map_buffer.get_block(pos)
			if block_id != -1:
				var block = block_library.get_block_by_id(block_id)
				if block:
					var type_name = block.name
					block_types[type_name] = block_types.get(type_name, 0) + 1
	
	info["block_types"] = block_types
	return info

func log_debug_info():
	"""Outputs debug information to logger"""
	var info = get_debug_info()
	Logger.info(TAG, "=== CHUNK DEBUG INFO ===")
	Logger.info(TAG, "Position: %s" % str(info.position))
	Logger.info(TAG, "Size: %s" % str(info.size))
	Logger.info(TAG, "Total blocks: %d" % info.total_blocks)
	Logger.info(TAG, "Overlays: %d" % info.overlay_count)
	Logger.info(TAG, "Surface blocks: %d" % info.surface_blocks)
	Logger.info(TAG, "Block types: %s" % str(info.block_types))
	Logger.info(TAG, "========================")
