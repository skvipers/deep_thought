class_name InteractableObject
extends BuildObject

## Наследуется от BuildObject, добавляет поддержку взаимодействия и логических компонентов

@export var logic_components: Array[LogicComponent] = []
@export var interaction_range: float = 2.0
@export var can_interact: bool = true

## Список акторов, которые могут взаимодействовать с объектом
var allowed_actors: Array = []

## Текущий актор, взаимодействующий с объектом
var current_interactor = null

## Инициализация из данных объекта
func init_from_data(data: BuildObjectData):
	super.init_from_data(data)
	
	# Создание логических компонентов из PackedScene
	for component_scene in data.logic_components:
		if component_scene != null:
			var component_instance = component_scene.instantiate()
			if component_instance is LogicComponent:
				component_instance.set_parent(self)
				logic_components.append(component_instance)
				component_instance.on_init()

## Взаимодействие с объектом
func interact(actor):
	if not can_interact or not is_built:
		return false
	
	# Проверка разрешенных акторов
	if not allowed_actors.is_empty() and not actor in allowed_actors:
		return false
	
	current_interactor = actor
	
	# Вызов взаимодействия для всех логических компонентов
	for component in logic_components:
		if component.is_component_enabled():
			component.on_interact(actor)
	
	return true

## Обновление объекта каждый тик
func update(delta: float):
	super.update_build_progress(delta)
	
	# Обновление логических компонентов
	for component in logic_components:
		if component.is_component_enabled():
			component.on_tick(delta)

## Добавляет логический компонент
func add_logic_component(component: LogicComponent):
	component.set_parent(self)
	logic_components.append(component)
	component.on_init()

## Удаляет логический компонент
func remove_logic_component(component: LogicComponent):
	if component in logic_components:
		logic_components.erase(component)

## Получает логический компонент по имени
func get_logic_component(component_name: String) -> LogicComponent:
	for component in logic_components:
		if component.component_name == component_name:
			return component
	return null

## Проверяет, может ли актор взаимодействовать с объектом
func can_actor_interact(actor) -> bool:
	if not can_interact or not is_built:
		return false
	
	if not allowed_actors.is_empty():
		return actor in allowed_actors
	
	return true

## Устанавливает список разрешенных акторов
func set_allowed_actors(actors: Array):
	allowed_actors = actors

## Добавляет разрешенного актора
func add_allowed_actor(actor):
	if not actor in allowed_actors:
		allowed_actors.append(actor)

## Удаляет разрешенного актора
func remove_allowed_actor(actor):
	allowed_actors.erase(actor)

## Возвращает приоритет объекта
func get_priority() -> int:
	return priority

## Устанавливает приоритет объекта
func set_priority(new_priority: int):
	priority = new_priority

## Возвращает диапазон взаимодействия
func get_interaction_range() -> float:
	return interaction_range

## Устанавливает диапазон взаимодействия
func set_interaction_range(range: float):
	interaction_range = range 
