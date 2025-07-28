extends Node
class_name Planet

const TAG := "Planet"

@export var config: PlanetConfig
@export var biome_generator: BiomeGenerator

var tiles: Array[CustomTileData] = []

func generate(raw_data: Dictionary) -> void:
	tiles.clear()

	if not raw_data.has("hex_centers") or not raw_data.has("hex_neighbors"):
		Logger.error(TAG, "Missing hex_centers or hex_neighbors in raw_data")
		return

	# Step 1: Create tile data
	for i in raw_data.hex_centers.size():
		var tile := CustomTileData.new()
		tile.center = raw_data.hex_centers[i]
		tile.neighbors = raw_data.hex_neighbors.get(i, [])
		tiles.append(tile)

	Logger.debug(TAG, "Generated %d tiles" % tiles.size())

	# Step 2: Assign biomes using the generator
	if biome_generator:
		Logger.debug(TAG, "Generating biomes using: %s" % biome_generator.get_class())
		biome_generator.generate_biomes(tiles, config)
	else:
		Logger.warn(TAG, "Biome generator not assigned")

func get_latitude(vec: Vector3) -> float:
	return rad_to_deg(asin(vec.normalized().y))
