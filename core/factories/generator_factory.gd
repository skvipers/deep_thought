class_name GeneratorFactory

static func create_basic_terrain_generator(preset, height_generator, tile_data) -> BasicTerrainGenerator:
	var gen = BasicTerrainGenerator.new()
	gen.preset = preset
	gen.height_generator = height_generator
	gen.tile_data = tile_data
	return gen

static func create_advanced_terrain_generator(preset, height_generator, tile_data) -> AdvancedTerrainGenerator:
	var gen = AdvancedTerrainGenerator.new()
	gen.preset = preset
	gen.height_generator = height_generator
	gen.tile_data = tile_data
	return gen

static func create_test_terrain_generator(preset) -> TestTerrainGenerator:
	var gen = TestTerrainGenerator.new()
	gen.preset = preset
	return gen 