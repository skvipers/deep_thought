class_name BuildPreviewController
extends RefCounted

## Контроллер для управления призраками строений

var current_ghost: GhostBuildObject
var build_system: BuildSystemManager
var occupancy_manager: OccupancyManager
var build_factory: BuildObjectFactory

## Сигналы
signal ghost_created(ghost: GhostBuildObject)
signal ghost_updated(ghost: GhostBuildObject, position: Vector3, is_valid: bool)
signal ghost_removed(ghost: GhostBuildObject)

## Инициализация контроллера
func initialize(build_sys: BuildSystemManager, occupancy_mgr: OccupancyManager, factory: BuildObjectFactory):
	build_system = build_sys
	occupancy_manager = occupancy_mgr
	build_factory = factory

## Создает призрак для объекта
func create_ghost(object_id: String) -> GhostBuildObject:
	# Получаем данные объекта
	var object_data = build_factory.get_object_data(object_id)
	if object_data == null:
		return null
	
	# Создаем призрак
	var ghost = GhostBuildObject.new()
	ghost.initialize_from_data(object_data)
	
	current_ghost = ghost
	ghost_created.emit(ghost)
	
	return ghost

## Обновляет позицию призрака
func update_ghost_position(position: Vector3):
	if current_ghost == null:
		return
	
	# Устанавливаем позицию
	current_ghost.set_position(position)
	
	# Проверяем валидность размещения
	var grid_pos = Vector3i(position)
	var is_valid = occupancy_manager.is_space_free(grid_pos, current_ghost.size)
	
	# Обновляем визуал
	current_ghost.set_validity(is_valid)
	
	ghost_updated.emit(current_ghost, position, is_valid)

## Обновляет поворот призрака
func update_ghost_rotation(rotation: int):
	if current_ghost == null:
		return
	
	current_ghost.set_object_rotation(rotation)
	
	# Перепроверяем валидность с новым поворотом
	var position = current_ghost.global_position
	var grid_pos = Vector3i(position)
	var rotated_size = current_ghost.get_rotated_size()
	var is_valid = occupancy_manager.is_space_free(grid_pos, rotated_size)
	
	current_ghost.set_validity(is_valid)
	
	ghost_updated.emit(current_ghost, position, is_valid)

## Размещает объект в позиции призрака
func place_object_at_ghost_position() -> BuildObject:
	if current_ghost == null:
		return null
	
	var position = current_ghost.global_position
	var grid_pos = Vector3i(position)
	var object_id = current_ghost.get_object_data().id
	
	# Проверяем валидность
	if not current_ghost.is_placement_valid():
		return null
	
	# Размещаем объект
	var placed_object = build_system.create_and_place_object(object_id, grid_pos)
	
	if placed_object != null:
		# Удаляем призрак
		remove_current_ghost()
	
	return placed_object

## Удаляет текущий призрак
func remove_current_ghost():
	if current_ghost != null:
		var ghost = current_ghost
		current_ghost = null
		
		# Анимация исчезновения
		ghost.animate_disappearance()
		
		ghost_removed.emit(ghost)

## Показывает призрак
func show_ghost():
	if current_ghost != null:
		current_ghost.show_ghost()
		current_ghost.animate_appearance()

## Скрывает призрак
func hide_ghost():
	if current_ghost != null:
		current_ghost.hide_ghost()

## Возвращает текущий призрак
func get_current_ghost() -> GhostBuildObject:
	return current_ghost

## Проверяет, есть ли активный призрак
func has_active_ghost() -> bool:
	return current_ghost != null

## Возвращает валидность текущего призрака
func is_current_ghost_valid() -> bool:
	if current_ghost == null:
		return false
	return current_ghost.is_placement_valid()

## Очищает контроллер
func clear():
	if current_ghost != null:
		remove_current_ghost() 
