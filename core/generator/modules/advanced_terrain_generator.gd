extends ChunkGenerationModule
class_name AdvancedTerrainGenerator

const TAG := "BasicTerrain"
const OVERRIDABLE_NOISE_KEYS := [
	"frequency", "amplitude", "offset", "octaves", "lacunarity", "gain"
]

@export var preset: GeneratorPreset
@export var height_generator: NoiseGenerator
@export var tile_data: CustomTileData

func generate_chunk(buffer: MapBuffer, context: GenerationContext, chunk_pos: Vector3i, chunk_size: Vector3i) -> void:
	if not height_generator:
		Logger.error(TAG, "Height noise not assigned")
		return

	var block_library = context.block_library
	if not block_library:
		Logger.error(TAG, "BlockLibrary not found in context")
		return

	var biome = tile_data.biome if tile_data and tile_data.biome else null

	# Override noise parameters if defined in biome
	if biome and biome.noise_override:
		for key in biome.noise_override:
			if key in OVERRIDABLE_NOISE_KEYS:
				height_generator.set(key, biome.noise_override[key])
		height_generator._update_noise()

	var surface_block_id = BiomeUtils.get_block_id(biome, "surface_block", block_library) if biome else block_library.get_block_id(preset.surface_block)
	var subsoil_block_id = BiomeUtils.get_block_id(biome, "subsoil_block", block_library) if biome else block_library.get_block_id(preset.subsoil_block)
	var top_layer_block_id = BiomeUtils.get_block_id(biome, "top_layer_block", block_library) if biome else block_library.get_block_id(preset.top_layer_block)

	Logger.debug(TAG, "Resolved block IDs: top=%d, surface=%d, subsoil=%d" % [
		top_layer_block_id, surface_block_id, subsoil_block_id
	])
	if surface_block_id == -1 or subsoil_block_id == -1 or top_layer_block_id == -1:
		Logger.warn(TAG, "One or more block types not found in BlockLibrary")
		return

	var surface_depth = BiomeUtils.get_config_int(biome, "surface_depth", preset.surface_depth) if biome else preset.surface_depth
	var surface_level = BiomeUtils.get_config_int(biome, "surface_level", preset.surface_level) if biome else preset.surface_level

	if surface_level >= chunk_size.y:
		Logger.warn(TAG, "⚠️ Surface level (%d) exceeds chunk height (%d), clamping..." % [surface_level, chunk_size.y])
		surface_level = chunk_size.y - 1

	for x in range(chunk_size.x):
		for z in range(chunk_size.z):
			var world_x = x + chunk_pos.x * chunk_size.x
			var world_z = z + chunk_pos.z * chunk_size.z

			var noise_val = height_generator.get_noise_3d(world_x, 0.0, world_z)
			var height = surface_level + int(noise_val * 0.5 * chunk_size.y)
			height = clamp(height, 0, chunk_size.y - 1)

			for y in range(chunk_size.y):
				var pos = Vector3i(x, y, z)

				if y == height:
					buffer.set_block(pos, surface_block_id)
				elif y < height - surface_depth:
					buffer.set_block(pos, subsoil_block_id)
				elif y < height:
					if BiomeUtils.has_top_layer(biome):
						buffer.set_block(pos, top_layer_block_id)
					else:
						buffer.set_block(pos, surface_block_id)
	
	if context.has_method("get_overlay_manager"):
		var overlay_manager = context.get_overlay_manager()
		if overlay_manager:
			# Отложенное применение оверлеев после того как чанк создан
			call_deferred("apply_overlays_to_generated_chunk", overlay_manager, chunk_pos)

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
		Logger.error(
			TAG,
			"❌ Preset contains empty block names: top='%s', surface='%s', subsoil='%s'" %
			[preset.top_layer_block, preset.surface_block, preset.subsoil_block]
		)

	return names_ok

func apply_overlays_to_generated_chunk(overlay_manager: OverlayManager, chunk_pos: Vector3i):
	"""Применяет оверлеи к сгенерированному чанку"""
	overlay_manager.apply_natural_overlays_to_chunk(chunk_pos)
