extends Node
class_name Planet

const TAG := "Planet"
const TileUtils = preload("res://addons/deep_thought/core/world/planet/tile_utils.gd")

@export var config: PlanetConfig
@export var biome_generator: BiomeGenerator
@export var planet_scene: PackedScene  # Сцена планеты, передаваемая извне

var tiles: Array[CustomTileData] = []
var planet_scene_instance: Node3D

func _ready():
	if planet_scene:
		load_planet_scene()

func load_planet_scene():
	if not planet_scene:
		Logger.warn(TAG, "Planet scene not assigned")
		return
	
	# Удаляем старую сцену если есть
	if planet_scene_instance:
		planet_scene_instance.queue_free()
	
	# Загружаем новую сцену
	planet_scene_instance = planet_scene.instantiate()
	add_child(planet_scene_instance)
	
	Logger.info(TAG, "Loaded planet scene: %s" % planet_scene.resource_path)

## Установить сцену планеты извне
func set_planet_scene(scene: PackedScene):
	planet_scene = scene
	if is_inside_tree():
		load_planet_scene()

## Получить PlanetMesh из загруженной сцены
func get_planet_mesh() -> Node:
	if not planet_scene_instance:
		return null
	
	# Ищем PlanetMesh в загруженной сцене
	var planet_mesh = planet_scene_instance.find_child("PlanetMesh", true, false)
	if not planet_mesh:
		Logger.warn(TAG, "PlanetMesh not found in planet scene")
		return null
	
	return planet_mesh

## Получить все компоненты планеты
func get_planet_components() -> Dictionary:
	var components = {}
	
	if planet_scene_instance:
		components["planet_mesh"] = get_planet_mesh()
		components["camera"] = planet_scene_instance.find_child("Camera3D", true, false)
		components["world_environment"] = planet_scene_instance.find_child("WorldEnvironment", true, false)
		components["star"] = planet_scene_instance.find_child("Star", true, false)
		components["ui"] = planet_scene_instance.find_child("CanvasLayer", true, false)
	
	return components

func generate(raw_data: Dictionary) -> void:
	tiles.clear()

	if not raw_data.has("hex_centers") or not raw_data.has("hex_neighbors"):
		Logger.error(TAG, "Missing hex_centers or hex_neighbors in raw_data")
		return

	# Step 1: Create tile data using TileUtils
	tiles = TileUtils.create_tiles_from_geometry(
		raw_data.hex_centers,
		raw_data.hex_neighbors,
		raw_data.hex_boundaries
	)

	Logger.debug(TAG, "Generated %d tiles" % tiles.size())

	# Step 2: Assign biomes using the generator
	if biome_generator:
		Logger.debug(TAG, "Generating biomes using: %s" % biome_generator.get_class())
		biome_generator.generate_biomes(tiles, config)
		
		# Step 3: Update tile colors after biome assignment
		for tile in tiles:
			if tile.biome:
				tile.biome_color = tile.biome.color
				tile.biome_id = tile.biome.name
			else:
				tile.biome_color = Color.MAGENTA
				tile.biome_id = "None"
	else:
		Logger.warn(TAG, "Biome generator not assigned")

func get_latitude(vec: Vector3) -> float:
	return rad_to_deg(asin(vec.normalized().y))
