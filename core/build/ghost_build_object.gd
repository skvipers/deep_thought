class_name GhostBuildObject
extends Node3D

## Призрак строительного объекта для предварительного просмотра

@export var valid_material: Material
@export var invalid_material: Material

var object_id: String = ""
var object_size: Vector3i = Vector3i(1, 1, 1)
var object_rotation: float = 0.0
var ghost_mesh: MeshInstance3D
var target_position: Vector3
var lerp_speed: float = 15.0

func _ready():
	# Создаем визуальное представление призрака
	_create_ghost_visual()
	# Устанавливаем начальную целевую позицию
	target_position = global_position
	
	# Включаем обработку в _process
	set_process(true)

func _process(delta):
	# Плавное движение к целевой позиции
	global_position = global_position.lerp(target_position, delta * lerp_speed)

	
	# Принудительно показываем призрак
	show_ghost()
	
	# Убеждаемся, что призрак видим
	visible = true
	if ghost_mesh:
		ghost_mesh.visible = true

func _exit_tree():
	Logger.debug("GHOST", "Ghost being removed from tree")

## Инициализирует призрак из объекта
func initialize_from_object(build_object: BuildObject, p_valid_material: Material, p_invalid_material: Material):
	valid_material = p_valid_material
	invalid_material = p_invalid_material
	object_id = build_object.object_id
	object_size = build_object.size
	object_rotation = 0.0  # Начинаем с 0 градусов
	
	# Убеждаемся, что размер разумный
	if object_size.x <= 0 or object_size.y <= 0 or object_size.z <= 0:
		Logger.warn("GHOST", "Invalid object size: " + str(object_size) + ", using default")
		object_size = Vector3i(1, 1, 1)
	
	# Ограничиваем максимальный размер для видимости
	var max_size = 10
	if object_size.x > max_size or object_size.y > max_size or object_size.z > max_size:
		Logger.warn("GHOST", "Object size too large: " + str(object_size) + ", clamping")
		object_size.x = min(object_size.x, max_size)
		object_size.y = min(object_size.y, max_size)
		object_size.z = min(object_size.z, max_size)
	
	# Принудительно делаем минимальный размер для видимости
	var min_size = 0.5
	if object_size.x < min_size or object_size.y < min_size or object_size.z < min_size:
		Logger.warn("GHOST", "Object size too small: " + str(object_size) + ", increasing")
		object_size.x = max(object_size.x, min_size)
		object_size.y = max(object_size.y, min_size)
		object_size.z = max(object_size.z, min_size)
	
	Logger.debug("GHOST", "Initialized with size: " + str(object_size))
	
	# Обновляем визуальное представление
	_update_ghost_visual()

## Создает визуальное представление призрака
func _create_ghost_visual():
	ghost_mesh = MeshInstance3D.new()
	add_child(ghost_mesh)
	
	# Создаем куб как базовую форму
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(object_size)
	ghost_mesh.mesh = box_mesh
	
	# Устанавливаем начальный материал
	if valid_material:
		ghost_mesh.material_override = valid_material
	else:
		Logger.warn("GHOST", "Valid material is not set for GhostBuildObject")
	
	Logger.debug("GHOST", "Created ghost visual with size: " + str(object_size))

## Обновляет визуальное представление
func _update_ghost_visual():
	if ghost_mesh:
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(object_size)
		ghost_mesh.mesh = box_mesh

## Показывает призрак
func show_ghost():
	visible = true
	if ghost_mesh:
		ghost_mesh.visible = true
	Logger.debug("GHOST", "Ghost shown - visible: " + str(visible) + ", mesh visible: " + str(ghost_mesh.visible if ghost_mesh else "no mesh"))

## Скрывает призрак
func hide_ghost():
	visible = false
	if ghost_mesh:
		ghost_mesh.visible = false
	Logger.debug("GHOST", "Ghost hidden")



## Устанавливает позицию призрака
func set_ghost_position(position: Vector3):
	target_position = position

## Устанавливает поворот призрака
func set_ghost_rotation(rot: float):
	object_rotation = rot
	rotation.y = deg_to_rad(rot)

## Получает позицию призрака
func get_ghost_position() -> Vector3:
	return global_position

## Получает размер призрака
func get_ghost_size() -> Vector3:
	return Vector3(object_size)

## Получает поворот призрака
func get_ghost_rotation() -> float:
	return object_rotation

## Получает ID объекта
func get_object_id() -> String:
	return object_id

## Проверяет состояние призрака
func check_ghost_state():
	Logger.debug("GHOST", "Ghost state check:")
	Logger.debug("GHOST", "  - Visible: " + str(visible))
	Logger.debug("GHOST", "  - Position: " + str(position))
	Logger.debug("GHOST", "  - Object ID: " + object_id)
	Logger.debug("GHOST", "  - Object size: " + str(object_size))
	if ghost_mesh:
		Logger.debug("GHOST", "  - Mesh visible: " + str(ghost_mesh.visible))
		Logger.debug("GHOST", "  - Mesh position: " + str(ghost_mesh.position))
		if ghost_mesh.material_override:
			Logger.debug("GHOST", "  - Material: " + str(ghost_mesh.material_override.resource_path))
	else:
		Logger.debug("GHOST", "  - No mesh")
	Logger.debug("GHOST", "  - Parent: " + (get_parent().name if get_parent() else "no parent"))
	
	# Проверяем видимость в камере
	var camera = get_viewport().get_camera_3d()
	if camera:
		var screen_pos = camera.unproject_position(position)
		Logger.debug("GHOST", "  - Screen position: " + str(screen_pos))
		Logger.debug("GHOST", "  - Distance to camera: " + str(position.distance_to(camera.global_position)))
		
		# Проверяем, находится ли призрак в поле зрения камеры
		var viewport_size = get_viewport().get_visible_rect().size
		if screen_pos.x < 0 or screen_pos.x > viewport_size.x or screen_pos.y < 0 or screen_pos.y > viewport_size.y:
			Logger.warn("GHOST", "Ghost outside camera viewport!")
		else:
			Logger.debug("GHOST", "Ghost is in camera viewport")
	else:
		Logger.debug("GHOST", "No camera found")

## Обновляет цвет призрака в зависимости от валидности
func update_validity(is_valid: bool):
	if ghost_mesh:
		if is_valid:
			if valid_material:
				ghost_mesh.material_override = valid_material
			else:
				Logger.warn("GHOST", "Valid material is not set.")
		else:
			if invalid_material:
				ghost_mesh.material_override = invalid_material
			else:
				Logger.warn("GHOST", "Invalid material is not set.")
		Logger.debug("GHOST", "Updated validity: " + str(is_valid))
