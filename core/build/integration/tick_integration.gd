class_name BuildTickIntegration
extends RefCounted

## Интеграция строительной системы с системой времени

var tick_manager = null
var build_grid = null

## Инициализация интеграции
func initialize(tick_mgr: Object, build_g: Object):
	tick_manager = tick_mgr
	build_grid = build_g

## Регистрирует объект в системе тиков
func register_object_for_ticking(object: Object):
	if tick_manager == null:
		return
	
	# Создаем тикабельный объект для строительного объекта
	var tickable_object = {
		"object": object,
		"tick_rate": 1.0,  # Тик в секунду
		"last_tick": 0.0,
		"enabled": true
	}
	
	tick_manager.register_tickable(tickable_object)

## Отменяет регистрацию объекта
func unregister_object_from_ticking(object: Object):
	if tick_manager == null:
		return
	
	tick_manager.unregister_tickable(object)

## Обрабатывает тик для строительного объекта
func process_build_object_tick(tickable: Dictionary, delta: float) -> bool:
	var object = tickable.get("object", null)
	
	if object == null:
		return false
	
	# Обновляем объект
	if object.has_method("update"):
		object.update(delta)
	
	# Проверяем завершение строительства
	if object.has_method("update_build_progress"):
		object.update_build_progress(delta)
		
		# Если строительство завершено, уведомляем систему
		if object.is_built:
			_on_build_completed(object)
	
	return true

## Обрабатывает тик для интерактивного объекта
func process_interactable_tick(tickable: Dictionary, delta: float) -> bool:
	var object = tickable.get("object", null)
	
	if object == null:
		return false
	
	# Обновляем интерактивный объект
	if object.has_method("update"):
		object.update(delta)
	
	# Проверяем логические компоненты
	if object.has_method("get_logic_components"):
		for component in object.logic_components:
			if component.has_method("on_tick"):
				component.on_tick(delta)
	
	return true

## Вызывается при завершении строительства
func _on_build_completed(build_object: Object):
	print("Build completed: ", build_object.display_name)
	
	# Здесь можно добавить дополнительные действия
	# Например, уведомление системы приоритетов, создание событий и т.д.

## Устанавливает частоту тиков для объекта
func set_object_tick_rate(object: Object, tick_rate: float):
	if tick_manager == null:
		return
	
	var tickable = tick_manager.get_tickable(object)
	if tickable != null:
		tickable["tick_rate"] = tick_rate

## Включает/выключает тики для объекта
func set_object_ticking_enabled(object: Object, enabled: bool):
	if tick_manager == null:
		return
	
	var tickable = tick_manager.get_tickable(object)
	if tickable != null:
		tickable["enabled"] = enabled

## Регистрирует все объекты в сетке для тиков
func register_all_objects_for_ticking():
	if build_grid == null:
		return
	
	var all_objects = build_grid.get_all_objects()
	
	for object in all_objects:
		register_object_for_ticking(object)

## Отменяет регистрацию всех объектов
func unregister_all_objects_from_ticking():
	if build_grid == null:
		return
	
	var all_objects = build_grid.get_all_objects()
	
	for object in all_objects:
		unregister_object_from_ticking(object)

## Получает статистику тиков
func get_tick_statistics() -> Dictionary:
	if tick_manager == null:
		return {}
	
	var stats = {
		"total_objects": 0,
		"active_objects": 0,
		"build_objects": 0,
		"interactable_objects": 0
	}
	
	if build_grid != null:
		var all_objects = build_grid.get_all_objects()
		stats["total_objects"] = all_objects.size()
		
		for object in all_objects:
			if object.is_built:
				stats["active_objects"] += 1
			
			if object is BuildObject:
				stats["build_objects"] += 1
			
			if object is InteractableObject:
				stats["interactable_objects"] += 1
	
	return stats 
