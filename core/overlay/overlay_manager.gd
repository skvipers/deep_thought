extends Node
class_name OverlayManager

@export var auto_generate_grass: bool = true
@export var grass_density: float = 0.7  # Probability of grass on suitable blocks
@export var grass_strength_min: float = 0.8
@export var grass_strength_max: float = 1.0

var world_base: WorldBase
var pending_updates: Array[Vector3i] = []
var computed_surface_height_cache: Dictionary = {}

const TAG := "OverlayManager"

func _init(world: WorldBase):
	world_base = world

func add_overlay_at(world_pos: Vector3i, type: int, strength: float, direction: int = 0):
	#Logger.debug(TAG, "Adding overlay type %d at %s" % [type, str(world_pos)])
	
	var base_block = world_base.get_block_at(world_pos)
	if not base_block or not base_block.is_solid:
		Logger.warn(TAG, "No solid base block at %s" % str(world_pos))
		return
	
	var chunk = world_base.get_chunk_at_position(world_pos)
	if not chunk:
		Logger.warn(TAG, "Chunk not found for position %s" % str(world_pos))
		return
	
	var local_pos = chunk.world_to_local_position(world_pos)
	
	# Validate local coordinates are within chunk bounds
	if not chunk.is_position_in_chunk(local_pos):
		Logger.error(TAG, "Local position %s outside chunk bounds for world_pos %s" % [
			str(local_pos), str(world_pos)
		])
		return
	
	# Get or create overlay state
	var state = chunk.get_overlay(local_pos)
	if not state:
		state = BlockOverlayState.new()
	
	state.add_overlay(type, strength, direction)
	chunk.set_overlay(local_pos, state)
	
	#Logger.debug(TAG, "Successfully added overlay type %d at %s" % [type, str(world_pos)])

func spread_overlay(center: Vector3i, type: int, radius: int, strength: float):
	"""Spreads overlay effect in radius around center position"""
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			for z in range(-radius, radius + 1):
				var dist = Vector3(x, y, z).length()
				if dist <= radius:
					var falloff = 1.0 - (dist / float(radius))
					add_overlay_at(center + Vector3i(x, y, z), type, strength * falloff)

func remove_overlay_at(world_pos: Vector3i, type: BlockOverlay.OverlayType):
	"""Removes overlay of specific type at world position"""
	var chunk = world_base.get_chunk_at_position(world_pos)
	if not chunk:
		return
	
	var local_pos = chunk.world_to_local_position(world_pos)
	var state = chunk.get_overlay(local_pos)
	
	if state:
		state.remove_overlay(type)
		if state.get_total_coverage() <= 0.01:
			chunk.overlay_states.erase(local_pos)
		chunk.mark_for_rebuild()

func apply_natural_overlays_to_chunk(chunk_pos: Vector3i):
	"""Applies natural overlays after chunk generation"""
	var chunk_size = world_base.get_chunk_size()
	var chunk = world_base.get_chunk_at_position(chunk_pos * chunk_size)
	if not chunk:
		Logger.warn(TAG, "Chunk not found at %s" % str(chunk_pos))
		return
	
	Logger.debug(TAG, "Applying natural overlays to chunk %s" % str(chunk_pos))
	
	var grass_added = 0
	
	# Process all positions in chunk
	for x in range(chunk_size.x):
		for z in range(chunk_size.z):
			if apply_natural_overlays_to_column(chunk_pos, Vector3i(x, 0, z), chunk_size):
				grass_added += 1
	
	Logger.info(TAG, "Added %d natural overlays to chunk %s" % [grass_added, str(chunk_pos)])

func apply_natural_overlays_to_column(chunk_pos: Vector3i, local_column: Vector3i, chunk_size: Vector3i) -> bool:
	"""Applies natural overlays to block column. Returns true if overlay was added."""
	
	# Search for surface blocks in column (top to bottom)
	for y in range(chunk_size.y - 1, -1, -1):
		var local_pos = Vector3i(local_column.x, y, local_column.z)
		var world_pos = chunk_pos * chunk_size + local_pos
		
		# Get block
		var block = world_base.get_block_at(world_pos)
		if not block or not block.is_solid:
			continue
		
		# Check if this is a surface block
		var above_pos = world_pos + Vector3i(0, 1, 0)
		var has_block_above = world_base.has_block_at(above_pos)
		
		if not has_block_above and block.is_surface_candidate:
			# Apply grass if block allows it
			if block.allow_grass_overlay:
				var grass_chance = block.natural_overlay_chance if block.natural_overlay_chance > 0 else 0.8
				if randf() < grass_chance:
					add_overlay_at(world_pos, 1, randf_range(0.7, 1.0), 0)  # GRASS overlay
					apply_additional_natural_overlays(world_pos, block)
					return true
		
		# Found first solid block in column, move to next column
		break
	
	return false

func apply_additional_natural_overlays(world_pos: Vector3i, block: BlockType):
	"""Applies additional natural overlays based on block type"""
	
	# Example: leaves on wood blocks
	if "wood" in block.name.to_lower() or "log" in block.name.to_lower():
		if randf() < 0.3:  # 30% chance for leaves on wood
			add_overlay_at(world_pos, 2, randf_range(0.5, 0.8), 6)  # Leaves in all directions
	
	# Example: moss on stone blocks facing north
	if "stone" in block.name.to_lower() or "rock" in block.name.to_lower():
		if randf() < 0.2:  # 20% chance for moss on stone
			add_overlay_at(world_pos, 3, randf_range(0.3, 0.6), 2)  # Moss facing north

func generate_grass_on_surface_blocks(center_pos: Vector3i, radius: int = 8, grass_strength: float = 1.0):
	"""Generates grass on all suitable surface blocks in area"""
	Logger.info(TAG, "Generating grass around %s with radius %d" % [str(center_pos), radius])
	
	var grass_added = 0
	var blocks_checked = 0
	
	# Process area
	for x in range(center_pos.x - radius, center_pos.x + radius + 1):
		for z in range(center_pos.z - radius, center_pos.z + radius + 1):
			# Find topmost solid block in this column
			var surface_pos = find_surface_block_at(Vector3i(x, center_pos.y, z))
			if surface_pos == Vector3i(-1, -1, -1):
				continue
				
			blocks_checked += 1
			
			# Check if block is suitable for grass
			if is_suitable_for_grass(surface_pos):
				# Add grass with slight randomness in strength
				var final_strength = grass_strength * randf_range(0.8, 1.0)
				if add_grass_overlay(surface_pos, final_strength):
					grass_added += 1
	
	Logger.info(TAG, "Added grass to %d/%d surface blocks" % [grass_added, blocks_checked])
	force_rebuild_affected_chunks(center_pos, radius)

func find_surface_block_at(column_pos: Vector3i) -> Vector3i:
	"""Finds topmost solid block in column, starting search from column_pos.y"""
	
	# Search downward from starting position
	for y in range(column_pos.y, column_pos.y - 32, -1):  # Search within 32 blocks down
		var check_pos = Vector3i(column_pos.x, y, column_pos.z)
		var block = world_base.get_block_at(check_pos)
		
		if block and block.is_solid:
			# Check that space above is empty
			var above_pos = check_pos + Vector3i(0, 1, 0)
			var block_above = world_base.get_block_at(above_pos)
			
			if not block_above or not block_above.is_solid:
				return check_pos  # This is a surface block
	
	return Vector3i(-1, -1, -1)  # Not found

func is_suitable_for_grass(pos: Vector3i) -> bool:
	"""Checks if block is suitable for placing grass"""
	var block = world_base.get_block_at(pos)
	if not block:
		return false
	
	# Check basic conditions
	if not block.allow_grass_overlay or not block.is_surface_candidate:
		return false
	
	# Check that space above is empty
	var above_pos = pos + Vector3i(0, 1, 0)
	var block_above = world_base.get_block_at(above_pos)
	if block_above and block_above.is_solid:
		return false
	
	# Check if overlay already exists
	var chunk = world_base.get_chunk_at_position(pos)
	if not chunk:
		return false
	
	var local_pos = chunk.world_to_local_position(pos)
	var existing_overlay = chunk.get_overlay(local_pos)
	
	if existing_overlay and existing_overlay.grass_strength > 0.1:
		return false  # Grass already exists
	
	return true

func add_grass_overlay(pos: Vector3i, strength: float = 1.0) -> bool:
	"""Adds grass overlay to specific block"""
	var chunk = world_base.get_chunk_at_position(pos)
	if not chunk:
		Logger.warn(TAG, "No chunk found for position %s" % str(pos))
		return false
	
	var local_pos = chunk.world_to_local_position(pos)
	
	# Create or update overlay state
	var overlay_state = chunk.get_overlay(local_pos)
	if not overlay_state:
		overlay_state = BlockOverlayState.new()
	
	# Configure grass (using correct property name)
	overlay_state.grass_strength = clamp(strength, 0.0, 1.0)
	overlay_state.grass_direction = BlockOverlay.Direction.UP
	
	# Save state
	chunk.set_overlay(local_pos, overlay_state)
	
	Logger.debug(TAG, "Added grass overlay to %s with strength %.2f" % [str(pos), strength])
	return true

func force_rebuild_affected_chunks(center_pos: Vector3i, radius: int):
	"""Force rebuilds all chunks affected by area"""
	var chunk_size = world_base.get_chunk_size()
	
	# Calculate chunk bounds using proper coordinate conversion
	var min_world = center_pos - Vector3i(radius, 0, radius)
	var max_world = center_pos + Vector3i(radius, 0, radius)
	
	var min_chunk = Vector3i(
		floor(float(min_world.x) / float(chunk_size.x)),
		floor(float(min_world.y) / float(chunk_size.y)),
		floor(float(min_world.z) / float(chunk_size.z))
	)
	var max_chunk = Vector3i(
		floor(float(max_world.x) / float(chunk_size.x)),
		floor(float(max_world.y) / float(chunk_size.y)),
		floor(float(max_world.z) / float(chunk_size.z))
	)
	
	var rebuilt_chunks = 0
	for cx in range(min_chunk.x, max_chunk.x + 1):
		for cz in range(min_chunk.z, max_chunk.z + 1):
			var chunk_world_pos = Vector3i(cx, min_chunk.y, cz) * chunk_size
			var chunk = world_base.get_chunk_at_position(chunk_world_pos)
			if chunk and chunk.has_method("force_rebuild"):
				chunk.force_rebuild()
				rebuilt_chunks += 1
	
	Logger.info(TAG, "Force rebuilt %d chunks" % rebuilt_chunks)

func auto_generate_grass_for_chunk(chunk: Node3D):
	"""Automatically generates grass for entire chunk"""
	if not auto_generate_grass:
		return
		
	Logger.info(TAG, "Auto-generating grass for chunk at %s" % str(chunk.get_chunk_position()))
	
	var chunk_world_pos = chunk.get_chunk_position() * chunk.get_chunk_size()
	var chunk_size = chunk.get_chunk_size()
	var grass_added = 0
	var blocks_checked = 0
	
	# Process entire chunk by columns
	for x in range(chunk_size.x):
		for z in range(chunk_size.z):
			var world_column_pos = chunk_world_pos + Vector3i(x, chunk_size.y / 2, z)
			
			# Find surface block in this column
			var surface_pos = find_surface_block_optimized(world_column_pos)
			if surface_pos == Vector3i(-1, -1, -1):
				continue
				
			blocks_checked += 1
			
			# Check if suitable for grass
			if is_suitable_for_grass(surface_pos):
				var block = world_base.get_block_at(surface_pos)
				if block and should_generate_overlay_on_block(block):
					var grass_strength = randf_range(grass_strength_min, grass_strength_max)
					if add_grass_overlay(surface_pos, grass_strength):
						grass_added += 1
	
	Logger.info(TAG, "Added grass to %d/%d surface blocks in chunk" % [grass_added, blocks_checked])
	
	# Rebuild chunk if grass was added
	if grass_added > 0:
		chunk.force_rebuild()

func should_generate_overlay_on_block(block: BlockType) -> bool:
	"""Determines if overlay should be generated on this block.
	Considers both general density AND specific block chance."""
	
	# First check general generation density
	if randf() > grass_density:
		return false
	
	# Then check chance for this block type
	if randf() > block.natural_overlay_chance:
		return false
		
	return true

func find_surface_block_optimized(column_pos: Vector3i) -> Vector3i:
	"""Optimized surface block search using cached surface level from biome data"""
	
	# Use cached surface level
	var estimated_surface = get_cached_surface_level(column_pos)
	var start_y = estimated_surface if estimated_surface != -1 else column_pos.y
	
	# First check at estimated surface level
	var surface_pos = check_surface_at_level(column_pos, start_y)
	if surface_pos != Vector3i(-1, -1, -1):
		return surface_pos
	
	# If empty at estimated level - search down (more likely)
	for y in range(start_y - 1, start_y - 8, -1):
		surface_pos = check_surface_at_level(column_pos, y)
		if surface_pos != Vector3i(-1, -1, -1):
			return surface_pos
	
	# If nothing below - search up
	for y in range(start_y + 1, start_y + 8):
		surface_pos = check_surface_at_level(column_pos, y)
		if surface_pos != Vector3i(-1, -1, -1):
			return surface_pos
	
	return Vector3i(-1, -1, -1)

func check_surface_at_level(column_pos: Vector3i, y: int) -> Vector3i:
	"""Checks if block at Y level is a surface block"""
	var check_pos = Vector3i(column_pos.x, y, column_pos.z)
	var block = world_base.get_block_at(check_pos)
	
	if block and block.is_solid:
		# Check that space above is empty
		var above_pos = check_pos + Vector3i(0, 1, 0)
		var block_above = world_base.get_block_at(above_pos)
		
		if not block_above or not block_above.is_solid:
			return check_pos  # This is a surface block
	
	return Vector3i(-1, -1, -1)

func get_cached_surface_level(column_pos: Vector3i) -> int:
	"""Gets COMPUTED surface height with caching.
	Caches result of expensive Perlin noise calculations."""
	var cache_key = Vector2i(column_pos.x, column_pos.z)
	
	if cache_key in computed_surface_height_cache:
		return computed_surface_height_cache[cache_key]
	
	# Expensive computations that should be cached
	var computed_height = compute_surface_height_from_noise(column_pos.x, column_pos.z)
	computed_surface_height_cache[cache_key] = computed_height
	return computed_height

func compute_surface_height_from_noise(x: int, z: int) -> int:
	"""Computes surface height using generator from context.
	This is an expensive operation that should be cached!"""
	
	# Get access to generation context through WorldPreview
	var world_preview = world_base as WorldPreview
	if not world_preview or not world_preview.context:
		Logger.warn(TAG, "No GenerationContext available, using fallback")
		return estimate_surface_empirically(Vector3i(x, 32, z))
	
	var context = world_preview.context
	if not context.generators or context.generators.is_empty():
		Logger.warn(TAG, "No generators in context, using fallback")
		return estimate_surface_empirically(Vector3i(x, 32, z))
	
	# Get first generator (usually surface generator)
	var surface_generator = context.generators[0]
	if not surface_generator:
		Logger.warn(TAG, "Surface generator is null, using fallback")
		return estimate_surface_empirically(Vector3i(x, 32, z))
	
	# Try different methods to get surface height
	if surface_generator.has_method("get_surface_height"):
		var height = surface_generator.get_surface_height(x, z)
		Logger.debug(TAG, "Got surface height %d from generator for (%d, %d)" % [height, x, z])
		return height
	
	if surface_generator.has_method("get_height_noise"):
		var noise = surface_generator.get_height_noise()
		if noise and noise.has_method("get_noise_2d"):
			var noise_value = noise.get_noise_2d(x, z)  # EXPENSIVE COMPUTATION
			var base_height = 32  # Base height (configurable)
			var height_variation = 16  # Maximum deviation
			var computed_height = int(base_height + noise_value * height_variation)
			Logger.debug(TAG, "Computed height %d from noise %.3f for (%d, %d)" % [computed_height, noise_value, x, z])
			return computed_height
	
	if surface_generator.has_method("get_height_at_position"):
		var height = surface_generator.get_height_at_position(Vector2i(x, z))
		Logger.debug(TAG, "Got height %d from position method for (%d, %d)" % [height, x, z])
		return height
	
	if surface_generator.has_method("get_surface_level_at"):
		var height = surface_generator.get_surface_level_at(x, z, context)
		Logger.debug(TAG, "Got surface level %d for (%d, %d)" % [height, x, z])
		return height
	
	# Fallback: empirical estimation if nothing works
	Logger.debug(TAG, "No height method found in generator '%s', using empirical estimation" % surface_generator.get_class())
	return estimate_surface_empirically(Vector3i(x, 32, z))

func estimate_surface_empirically(column_pos: Vector3i) -> int:
	"""Quick empirical estimation without expensive computations"""
	# Check several standard levels
	var test_levels = [32, 28, 36, 24, 40, 20, 44]
	
	for test_y in test_levels:
		var test_pos = Vector3i(column_pos.x, test_y, column_pos.z)
		var block = world_base.get_block_at(test_pos)
		if block and block.is_solid:
			return test_y
	
	return 32  # Default average level

func clear_surface_cache():
	"""Clears cached computed heights (call when changing worlds)"""
	computed_surface_height_cache.clear()

func debug_surface_generator_info():
	"""Outputs information about available surface generator methods for debugging"""
	var world_preview = world_base as WorldPreview
	if not world_preview or not world_preview.context or not world_preview.context.generators:
		Logger.info(TAG, "No surface generator available for debugging")
		return
	
	var surface_generator = world_preview.context.generators[0]
	if not surface_generator:
		Logger.info(TAG, "Surface generator is null")
		return
		
	Logger.info(TAG, "=== SURFACE GENERATOR DEBUG INFO ===")
	Logger.info(TAG, "Generator class: %s" % surface_generator.get_class())
	Logger.info(TAG, "Available methods:")
	
	var available_methods = []
	if surface_generator.has_method("get_surface_height"):
		available_methods.append("get_surface_height(x, z)")
	if surface_generator.has_method("get_height_noise"):
		available_methods.append("get_height_noise()")
	if surface_generator.has_method("get_height_at_position"):
		available_methods.append("get_height_at_position(Vector2i)")
	if surface_generator.has_method("get_surface_level_at"):
		available_methods.append("get_surface_level_at(x, z, context)")
	
	if available_methods.is_empty():
		Logger.info(TAG, "  No recognized height methods found")
		Logger.info(TAG, "  Will use empirical surface detection")
	else:
		for method in available_methods:
			Logger.info(TAG, "  ✓ %s" % method)
	
	Logger.info(TAG, "Cache size: %d entries" % computed_surface_height_cache.size())
	Logger.info(TAG, "======================================")

func save_chunk_overlays(chunk_coords: Vector3i) -> OverlayChunkData:
	"""Saves overlay data for chunk to OverlayChunkData resource"""
	var chunk = world_base.get_chunk_at_position(chunk_coords * world_base.get_chunk_size())
	if not chunk:
		Logger.warn(TAG, "Cannot save overlays: chunk not found at %s" % str(chunk_coords))
		return null
	
	var data = OverlayChunkData.new()
	data.overlay_states = chunk.overlay_states.duplicate(true)
	
	Logger.debug(TAG, "Saved %d overlay states for chunk %s" % [data.overlay_states.size(), str(chunk_coords)])
	return data

func load_chunk_overlays(chunk_coords: Vector3i, data: OverlayChunkData):
	"""Loads overlay data for chunk from OverlayChunkData resource"""
	if not data:
		Logger.warn(TAG, "Cannot load overlays: data is null")
		return
	
	var chunk = world_base.get_chunk_at_position(chunk_coords * world_base.get_chunk_size())
	if not chunk:
		Logger.warn(TAG, "Cannot load overlays: chunk not found at %s" % str(chunk_coords))
		return
	
	chunk.overlay_states = data.overlay_states.duplicate(true)
	
	# Sync with renderer
	if chunk.renderer:
		chunk.renderer.overlay_states = chunk.overlay_states
		chunk.mark_for_rebuild()
	
	Logger.debug(TAG, "Loaded %d overlay states for chunk %s" % [chunk.overlay_states.size(), str(chunk_coords)])

func save_all_chunk_overlays_to_directory(directory_path: String):
	"""Saves all loaded chunks' overlays to directory (for debugging/backup)"""
	if not DirAccess.dir_exists_absolute(directory_path):
		DirAccess.open("user://").make_dir_recursive(directory_path)
	
	var saved_count = 0
	
	# Iterate through all loaded chunks
	for child in world_base.get_children():
		if child is Chunk:
			var chunk_pos = child.get_chunk_position()
			var overlay_data = save_chunk_overlays(chunk_pos)
			
			if overlay_data and overlay_data.overlay_states.size() > 0:
				var file_path = "%s/chunk_%d_%d_%d.tres" % [directory_path, chunk_pos.x, chunk_pos.y, chunk_pos.z]
				overlay_data.save_to_file(file_path)
				saved_count += 1
	
	Logger.info(TAG, "Saved overlays for %d chunks to %s" % [saved_count, directory_path])
