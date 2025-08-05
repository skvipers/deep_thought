# Файл: addons/deep_thought/managers/resource_manager.gd
class_name ResourceManager
extends Node

## Словарь для хранения всех определений ресурсов, загруженных из файлов .tres
## Ключ - это id ресурса (String), значение - это GameResourceDefinition
var resource_definitions: Dictionary = {}

const DEFINITIONS_PATH = "res://addons/deep_thought/data/resources/definitions"

func _ready():
	load_all_definitions()

## Загружает все определения ресурсов из указанного пути
func load_all_definitions():
	var dir = DirAccess.open(DEFINITIONS_PATH)
	if not dir:
		Logger.error("ResourceManager", "Failed to open directory: " + DEFINITIONS_PATH)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource = load(DEFINITIONS_PATH.path_join(file_name))
			if resource is GameResourceDefinition:
				if resource.id:
					resource_definitions[resource.id] = resource
				else:
					Logger.warn("ResourceManager", "Resource file '%s' has an empty ID." % file_name)
		file_name = dir.get_next()
		
	Logger.info("ResourceManager", "Loaded %d resource definitions." % resource_definitions.size())

## Возвращает определение ресурса по его ID
func get_definition(id: String) -> GameResourceDefinition:
	return resource_definitions.get(id, null)
