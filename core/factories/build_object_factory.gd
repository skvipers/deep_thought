class_name BuildObjectFactory
extends RefCounted

## Автозагрузчик всех .tres объектов из data/build_objects/

# Импортируем CategoryData
const CategoryData = preload("res://addons/deep_thought/core/build/category_data.gd")

var _build_objects_data: Dictionary = {}
var _is_initialized: bool = false
var _build_objects_path: String = ""
var _categories_path: String = ""
var _default_category: String = "miscellaneous"

## Инициализация фабрики
func initialize():
	if _is_initialized:
		return
	
	_load_build_objects_data()
	_is_initialized = true

## Устанавливает пути для загрузки данных
func set_paths(build_objects_path: String, categories_path: String = ""):
	_build_objects_path = build_objects_path
	_categories_path = categories_path

## Устанавливает дефолтную категорию
func set_default_category(category: String):
	_default_category = category

## Загружает все данные строительных объектов
func _load_build_objects_data():
	if _build_objects_path.is_empty():
		push_error("BuildObjectFactory: Build objects path not set. Call set_paths() first.")
		return
		
	var build_objects_dir = _build_objects_path
	var dir = DirAccess.open(build_objects_dir)
	
	if dir == null:
		push_warning("BuildObjectFactory: Cannot open directory: " + build_objects_dir)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = build_objects_dir + file_name
			var resource = load(file_path)
			
			if resource is BuildObjectData:
				_build_objects_data[resource.id] = resource
				print("BuildObjectFactory: Loaded build object: " + resource.id)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

## Получает данные строительного объекта по ID
func get_build_object_data(id: String) -> BuildObjectData:
	if not _is_initialized:
		initialize()
	
	return _build_objects_data.get(id, null)

## Создает строительный объект по ID
func create_build_object(id: String) -> BuildObject:
	var data = get_build_object_data(id)
	if data == null:
		push_error("BuildObjectFactory: Build object with ID '" + id + "' not found")
		return null
	
	return data.create_build_object()

## Возвращает список всех доступных ID объектов
func get_all_object_ids() -> Array[String]:
	if not _is_initialized:
		initialize()
	
	return _build_objects_data.keys()

## Возвращает список всех данных объектов
func get_all_build_objects_data() -> Array[BuildObjectData]:
	if not _is_initialized:
		initialize()
	
	var result: Array[BuildObjectData] = []
	for data in _build_objects_data.values():
		result.append(data)
	return result

## Возвращает объекты по категории
func get_objects_by_category(category: String) -> Array[BuildObjectData]:
	var result: Array[BuildObjectData] = []
	
	for data in _build_objects_data.values():
		if data is BuildObjectData and data.category == category:
			result.append(data)
	
	return result

## Возвращает объекты по тегу
func get_objects_by_tag(tag: String) -> Array[BuildObjectData]:
	var result: Array[BuildObjectData] = []
	
	for data in _build_objects_data.values():
		if data is BuildObjectData and tag in data.tags:
			result.append(data)
	
	return result

## Проверяет, существует ли объект с указанным ID
func has_build_object(id: String) -> bool:
	if not _is_initialized:
		initialize()
	
	return _build_objects_data.has(id)

## Перезагружает данные объектов
func reload():
	_build_objects_data.clear()
	_is_initialized = false
	initialize()

## Загружает категории из указанной папки
func load_categories_from_path(path: String = "") -> Array[CategoryData]:
	if path.is_empty():
		path = _categories_path
		if path.is_empty():
			push_error("BuildObjectFactory: Categories path not set. Call set_paths() first.")
			return []
			
	var categories: Array[CategoryData] = []
	var dir = DirAccess.open(path)
	
	if dir == null:
		push_warning("BuildObjectFactory: Cannot open categories directory: " + path)
		return categories
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = path + "/" + file_name
			var resource = load(file_path)
			
			if resource is CategoryData:
				if resource.is_valid():
					categories.append(resource)
					print("BuildObjectFactory: Loaded category: " + resource.id)
				else:
					push_warning("BuildObjectFactory: Invalid category data in " + file_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Сортируем по приоритету
	categories.sort_custom(func(a, b): return a.priority < b.priority)
	
	return categories

## Проверяет и исправляет категории объектов
func validate_object_categories():
	var all_objects = get_all_build_objects_data()
	var valid_categories = []
	
	# Получаем список валидных категорий
	for category in load_categories_from_path():
		valid_categories.append(category.id)
	
	# Проверяем каждый объект
	for object in all_objects:
		if object.category.is_empty() or not valid_categories.has(object.category):
			print("BuildObjectFactory: Object '", object.id, "' has invalid category '", object.category, "', setting to '", _default_category, "'")
			object.category = _default_category 
