extends BiomeGenerator
class_name DefaultBiomeGenerator

const TAG := "DefaultBiomeGenerator"

func generate_biomes(tiles: Array, config: Resource) -> void:
	var planet_config := config as PlanetConfig
	if planet_config == null:
		Logger.error(TAG, "Invalid or missing PlanetConfig resource")
		return
	if planet_config.biomes.is_empty():
		Logger.warn(TAG, "No biomes provided in PlanetConfig")
		return

	var unassigned := tiles.duplicate()
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	while not unassigned.is_empty():
		var tile: CustomTileData = unassigned.pop_back()
		var chosen_biome: Biome = pick_biome(planet_config.biomes, rng)
		if chosen_biome == null:
			Logger.warn(TAG, "Biome selection returned null")
			continue

		# Fill a contiguous cluster of tiles with the chosen biome
		var to_fill := [tile]
		var cluster := []

		while to_fill.size() > 0 and cluster.size() < chosen_biome.size:
			var current: CustomTileData = to_fill.pop_front()
			if current.biome != null:
				continue

			current.biome = chosen_biome
			cluster.append(current)

			for neighbor_id in current.neighbors:
				if neighbor_id >= 0 and neighbor_id < tiles.size():
					var neighbor: CustomTileData = tiles[neighbor_id]
					if neighbor.biome == null and not to_fill.has(neighbor):
						to_fill.append(neighbor)

		Logger.debug(TAG, "Assigned biome '%s' to %d tiles" % [chosen_biome.name, cluster.size()])

func pick_biome(biomes: Array[Biome], rng: RandomNumberGenerator) -> Biome:
	var total_weight = 0.0
	for biome in biomes:
		total_weight += biome.frequency

	var choice = rng.randf_range(0.0, total_weight)
	var accum = 0.0

	for biome in biomes:
		accum += biome.frequency
		if choice <= accum:
			return biome

	Logger.warn(TAG, "Fallback triggered in pick_biome()")
	return biomes[rng.randi_range(0, biomes.size() - 1)]
