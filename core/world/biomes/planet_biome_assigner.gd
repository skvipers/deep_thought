extends Resource
class_name PlanetBiomeAssigner

@export var generator: BiomeGenerator

func assign_biomes(tiles: Array, config: Resource) -> void:
	if generator:
		generator.generate_biomes(tiles, config)
