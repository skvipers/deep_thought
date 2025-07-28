extends ChunkGenerationModule
class_name TestTerrainGenerator

const TAG := "BasicTerrain"

@export var preset: GeneratorPreset

func generate_chunk(buffer: MapBuffer, context: GenerationContext, chunk_position: Vector3i, chunk_size: Vector3i) -> void:
	Logger.debug(TAG, "Starting terrain generation...")

	context.block_library.ensure_initialized()

	if not validate_preset(preset):
		Logger.error(TAG, "Invalid preset!")
		return

	var surface_level := preset.surface_level
	var chunk_base_y := chunk_position.y * chunk_size.y
	var blocks_generated := 0

	for x in chunk_size.x:
		for z in chunk_size.z:
			for y in chunk_size.y:
				var global_y := chunk_base_y + y
				if global_y > surface_level:
					continue

				var local_pos := Vector3i(x, y, z)
				var depth := surface_level - global_y

				var block_name := get_block_name_by_depth(depth, global_y == surface_level)
				var block := context.block_library.get_block_by_name(block_name)
				if block != null:
					buffer.set_block(local_pos, block.id)
					blocks_generated += 1

	Logger.info(TAG, "✅ Terrain generation completed for chunk at %s. Blocks placed: %d" % [chunk_position, blocks_generated])

func get_block_name_by_depth(depth: int, is_top_layer: bool) -> String:
	if is_top_layer:
		return preset.top_layer_block
	elif depth <= preset.surface_depth:
		return preset.surface_block
	else:
		return preset.subsoil_block

func validate_preset(p: GeneratorPreset) -> bool:
	if preset == null:
		Logger.error(TAG, "❌ Preset is null.")
		return false

	var names_ok := (
		not preset.top_layer_block.is_empty() and
		not preset.surface_block.is_empty() and
		not preset.subsoil_block.is_empty()
	)

	if not names_ok:
		Logger.error(TAG, "❌ Preset contains empty block names: top='%s', surface='%s', subsoil='%s'" %
			[preset.top_layer_block, preset.surface_block, preset.subsoil_block])

	return names_ok
