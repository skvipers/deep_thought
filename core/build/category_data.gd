class_name CategoryData
extends Resource

## Ресурс для описания категории строительных объектов

@export var id: String = ""
@export var priority: int = 0
@export var icon: Texture2D
@export var description: String = ""

## Проверяет валидность данных категории
func is_valid() -> bool:
	return not id.is_empty()

## Возвращает локализованное название (ключ для системы локализации)
func get_localized_name() -> String:
	return id 