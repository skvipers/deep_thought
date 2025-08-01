extends Node
class_name BiomeUtils

static func get_block_id(biome: Biome, key: String, block_library: BlockLibrary) -> int:
	if not biome:
		return -1
	if not biome.generator_config.has(key):
		return -1
	var block_name = biome.generator_config[key]
	var block_id = block_library.get_block_id(block_name)
	return block_id

static func get_config_int(biome: Biome, key: String, default: int = 0) -> int:
	if not biome or not biome.generator_config.has(key):
		return default
	return int(biome.generator_config[key])

static func has_top_layer(biome: Biome) -> bool:
	return biome and biome.generator_config.has("top_layer_block") and str(biome.generator_config["top_layer_block"]).strip_edges() != ""
