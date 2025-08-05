class_name LogicComponent
extends Resource

## Базовый модуль поведения, подключаемый к интерактивным объектам

@export var priority: int = 0
@export var is_enabled: bool = true
@export var component_name: String = ""

## Ссылка на родительский объект
var parent_object: InteractableObject

## Инициализация компонента
func on_init():
	pass

## Обновление компонента каждый тик
func on_tick(delta: float):
	pass

## Взаимодействие с компонентом
func on_interact(actor):
	pass

## Активация компонента
func enable():
	is_enabled = true

## Деактивация компонента
func disable():
	is_enabled = false

## Устанавливает родительский объект
func set_parent(object: InteractableObject):
	parent_object = object

## Возвращает приоритет компонента
func get_priority() -> int:
	return priority

## Проверяет, активен ли компонент
func is_component_enabled() -> bool:
	return is_enabled 