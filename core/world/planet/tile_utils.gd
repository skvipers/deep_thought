extends RefCounted
class_name TileUtils

const TAG := "TileUtils"

# Конвертация CustomTileData в Dictionary (для обратной совместимости)
static func tile_to_dictionary(tile: CustomTileData) -> Dictionary:
	return tile.to_dictionary()

# Конвертация Dictionary в CustomTileData
static func dictionary_to_tile(data: Dictionary) -> CustomTileData:
	return CustomTileData.from_dictionary(data)

# Создание тайла с базовыми параметрами
static func create_tile(id: int, position: Vector3, neighbors: Array = []) -> CustomTileData:
	var tile = CustomTileData.new()
	tile.id = id
	tile.position = position
	tile.center = position
	tile.neighbors = neighbors
	tile.neighbor_count = neighbors.size()
	tile.type = "Land"
	tile.biome_id = "unknown"
	tile.biome_color = Color.MAGENTA
	return tile

# Обновление тайла из геометрических данных
static func update_tile_from_geometry(tile: CustomTileData, hex_centers: PackedVector3Array, 
		hex_neighbors: Dictionary, hex_boundaries: Dictionary) -> void:
	if tile.id >= 0 and tile.id < hex_centers.size():
		tile.position = hex_centers[tile.id]
		tile.center = hex_centers[tile.id]
		tile.neighbors = hex_neighbors.get(tile.id, [])
		tile.neighbor_count = tile.neighbors.size()
		
		if hex_boundaries.has(tile.id):
			tile.vertex_count = hex_boundaries[tile.id].size()

# Обновление цвета тайла на основе биома
static func update_tile_color_from_biome(tile: CustomTileData) -> void:
	if tile.biome:
		tile.biome_color = tile.biome.color
		tile.biome_id = tile.biome.name
	else:
		tile.biome_color = Color.MAGENTA
		tile.biome_id = "None"

# Получение информации о тайле в виде строки
static func get_tile_info_string(tile: CustomTileData) -> String:
	return "Tile ID: %d, Biome: %s, Neighbors: %d, Vertices: %d" % [
		tile.id, tile.biome_id, tile.neighbor_count, tile.vertex_count
	]

# Проверка валидности тайла
static func is_tile_valid(tile: CustomTileData) -> bool:
	return tile != null and tile.id >= 0

# Создание массива тайлов из геометрических данных
static func create_tiles_from_geometry(hex_centers: PackedVector3Array, 
		hex_neighbors: Dictionary, hex_boundaries: Dictionary = {}) -> Array[CustomTileData]:
	var tiles: Array[CustomTileData] = []
	
	for i in hex_centers.size():
		var tile = create_tile(i, hex_centers[i], hex_neighbors.get(i, []))
		
		if hex_boundaries.has(i):
			tile.vertex_count = hex_boundaries[i].size()
		
		tiles.append(tile)
	
	return tiles

# Фильтрация тайлов по типу
static func filter_tiles_by_type(tiles: Array[CustomTileData], tile_type: String) -> Array[CustomTileData]:
	var filtered: Array[CustomTileData] = []
	for tile in tiles:
		if tile.type == tile_type:
			filtered.append(tile)
	return filtered

# Фильтрация тайлов по биому
static func filter_tiles_by_biome(tiles: Array[CustomTileData], biome_name: String) -> Array[CustomTileData]:
	var filtered: Array[CustomTileData] = []
	for tile in tiles:
		if tile.biome_id == biome_name:
			filtered.append(tile)
	return filtered

# Поиск тайла по позиции
static func find_tile_by_position(tiles: Array[CustomTileData], position: Vector3, tolerance: float = 0.1) -> CustomTileData:
	for tile in tiles:
		if tile.position.distance_to(position) <= tolerance:
			return tile
	return null

# Получение соседних тайлов
static func get_neighbor_tiles(tile: CustomTileData, all_tiles: Array[CustomTileData]) -> Array[CustomTileData]:
	var neighbors: Array[CustomTileData] = []
	for neighbor_id in tile.neighbors:
		if neighbor_id >= 0 and neighbor_id < all_tiles.size():
			neighbors.append(all_tiles[neighbor_id])
	return neighbors 