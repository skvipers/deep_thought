class_name BuildObjectFactory
extends RefCounted

## Factory for creating buildable objects and categories.

var object_blueprints: Dictionary = {}
var category_blueprints: Dictionary = {}
var default_category: String = "miscellaneous"
var _is_initialized: bool = false

var object_paths: Array = []
var category_paths: Array = []

## Sets the paths for object and category resources.
func set_paths(objects_path: String, categories_path: String):
	object_paths.append(objects_path)
	category_paths.append(categories_path)

## Sets the default category for objects without a valid one.
func set_default_category(category: String):
	default_category = category

## Initializes the factory by loading all blueprints.
func initialize():
	_load_all_blueprints()
	_is_initialized = true
	Logger.info("FACTORY", "Initialization complete. Loaded %d categories and %d objects." % [category_blueprints.size(), object_blueprints.size()])

## Validates that all loaded objects have a corresponding category.
func validate_object_categories():
	for object_id in object_blueprints:
		var blueprint = object_blueprints[object_id]
		var category_name = blueprint.category if "category" in blueprint else default_category
		if not category_blueprints.has(category_name):
			Logger.warn("FACTORY", "Object '%s' has an invalid category '%s'. It will be assigned to the default category '%s'." % [object_id, category_name, default_category])

## Loads all blueprints from the specified paths.
func _load_all_blueprints():
	# Load categories first.
	for path in category_paths:
		_load_resources_from_path(path, category_blueprints, "Category")
	
	# Then load objects.
	for path in object_paths:
		_load_resources_from_path(path, object_blueprints, "Object")

## Loads all .tres resources from a given path into a target dictionary.
func _load_resources_from_path(path: String, target_dict: Dictionary, type_name: String):
	var dir = DirAccess.open(path)
	if not dir:
		Logger.error("FACTORY", "Failed to open directory: " + path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource = load(path + file_name)
			if resource and "id" in resource:
				var id = resource.id
				if id:
					target_dict[id] = resource
				else:
					Logger.warn("FACTORY", "Resource file '%s' has an empty ID." % file_name)
		file_name = dir.get_next()

## Creates a new instance of a build object from its blueprint.
func create_build_object(object_id: String) -> BuildObject:
	if object_blueprints.has(object_id):
		var blueprint = object_blueprints[object_id]
		if blueprint:
			return blueprint.duplicate()
	
	Logger.error("FACTORY", "Failed to create build object with ID: " + object_id)
	return null

## Returns an array of all loaded category blueprints.
func get_categories() -> Array:
	return category_blueprints.values()

## Returns an array of object blueprints belonging to a specific category.
func get_objects_by_category(category_id: String) -> Array:
	var result: Array = []
	for object_id in object_blueprints:
		var blueprint = object_blueprints[object_id]
		
		# Determine the object's final category.
		var final_category = default_category
		if "category" in blueprint:
			if category_blueprints.has(blueprint.category):
				final_category = blueprint.category
		
		# If the object's category matches, add it to the results.
		if final_category == category_id:
			result.append(blueprint)
			
	return result
