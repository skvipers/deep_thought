class_name BuildPriorityIntegration
extends RefCounted

## Интеграция строительной системы с системой приоритетов

var priority_system = null
var build_grid = null

## Инициализация интеграции
func initialize(priority_sys: Object, build_g: Object):
	priority_system = priority_sys
	build_grid = build_g

## Создает задачу строительства
func create_build_task(builder: Object, build_object: BuildObject, position: Vector3i) -> Object:
	if priority_system == null:
		return null
	
	# Создаем задачу строительства
	var build_task = {
		"type": "build",
		"builder": builder,
		"object": build_object,
		"position": position,
		"priority": build_object.priority,
		"progress": 0.0,
		"completed": false
	}
	
	# Добавляем в систему приоритетов
	priority_system.add_job(build_task)
	
	return build_task

## Создает задачу взаимодействия с объектом
func create_interaction_task(actor: Object, interactable: InteractableObject) -> Object:
	if priority_system == null:
		return null
	
	# Создаем задачу взаимодействия
	var interaction_task = {
		"type": "interact",
		"actor": actor,
		"object": interactable,
		"priority": interactable.priority,
		"completed": false
	}
	
	# Добавляем в систему приоритетов
	priority_system.add_job(interaction_task)
	
	return interaction_task

## Обрабатывает задачу строительства
func process_build_task(task: Dictionary, delta: float) -> bool:
	var build_object = task.get("object", null)
	var builder = task.get("builder", null)
	
	if build_object == null or builder == null:
		return true  # Задача завершена
	
	# Обновляем прогресс строительства
	var build_time = build_object.build_time
	var current_progress = task.get("progress", 0.0)
	
	current_progress += delta / build_time
	task["progress"] = current_progress
	
	# Проверяем завершение
	if current_progress >= 1.0:
		# Размещаем объект в сетке
		var position = task.get("position", Vector3i.ZERO)
		if build_grid != null:
			build_grid.place_object(position, build_object)
		
		task["completed"] = true
		return true
	
	return false  # Задача продолжается

## Обрабатывает задачу взаимодействия
func process_interaction_task(task: Dictionary) -> bool:
	var interactable = task.get("object", null)
	var actor = task.get("actor", null)
	
	if interactable == null or actor == null:
		return true
	
	# Выполняем взаимодействие
	var success = interactable.interact(actor)
	
	task["completed"] = true
	return true

## Получает все строительные задачи для актора
func get_build_tasks_for_actor(actor: Object) -> Array:
	if priority_system == null:
		return []
	
	var tasks = []
	var all_jobs = priority_system.get_all_jobs()
	
	for job in all_jobs:
		if job.get("type") == "build" and job.get("builder") == actor:
			tasks.append(job)
	
	return tasks

## Получает все задачи взаимодействия для актора
func get_interaction_tasks_for_actor(actor: Object) -> Array:
	if priority_system == null:
		return []
	
	var tasks = []
	var all_jobs = priority_system.get_all_jobs()
	
	for job in all_jobs:
		if job.get("type") == "interact" and job.get("actor") == actor:
			tasks.append(job)
	
	return tasks

## Отменяет задачу строительства
func cancel_build_task(task: Dictionary):
	if priority_system == null:
		return
	
	priority_system.remove_job(task)

## Отменяет задачу взаимодействия
func cancel_interaction_task(task: Dictionary):
	if priority_system == null:
		return
	
	priority_system.remove_job(task)

## Обновляет приоритеты объектов на основе их состояния
func update_object_priorities():
	if build_grid == null:
		return
	
	var all_objects = build_grid.get_all_objects()
	
	for object in all_objects:
		if object is InteractableObject:
			# Обновляем приоритет на основе состояния компонентов
			var new_priority = _calculate_object_priority(object)
			object.set_priority(new_priority)

## Вычисляет приоритет объекта на основе его состояния
func _calculate_object_priority(object: InteractableObject) -> int:
	var base_priority = object.priority
	
	# Проверяем состояние логических компонентов
	for component in object.logic_components:
		if component is ProductionComponent:
			var production = component as ProductionComponent
			
			# Увеличиваем приоритет если хранилище заполнено
			if production.is_storage_full():
				base_priority += 10
			
			# Увеличиваем приоритет если хранилище пустое
			if production.is_storage_empty():
				base_priority += 5
	
	return base_priority 
