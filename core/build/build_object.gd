class_name BuildObject
extends Resource

## Базовый класс строительного объекта, размещаемого в BuildGrid

@export var origin: Vector3i = Vector3i.ZERO
@export var size: Vector3i = Vector3i.ONE
@export var relative_cells: Array[Vector3i] = []
@export var rotation: int = 0

## Уникальный идентификатор объекта
@export var object_id: String = ""

## Название объекта для отображения
@export var display_name: String = ""

## Модель объекта
@export var mesh: Mesh

## Иконка для UI
@export var icon: Texture2D

## Можно ли взаимодействовать с объектом
@export var is_interactable: bool = false

## Приоритет объекта
@export var priority: int = 0

## Теги для категоризации
@export var tags: Array[String] = []

## Стоимость строительства
@export var build_cost: Dictionary = {}

## Время строительства в секундах
@export var build_time: float = 1.0

## Состояние строительства (0.0 - 1.0)
var build_progress: float = 0.0

## Завершено ли строительство
var is_built: bool = false

## Ссылка на ячейку сетки, где размещен объект
var grid_cell: BuildCell

func _init():
	# Инициализация относительных ячеек на основе размера
	if relative_cells.is_empty():
		_update_relative_cells()

## Обновляет массив относительных ячеек на основе размера объекта
func _update_relative_cells():
	relative_cells.clear()
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				relative_cells.append(Vector3i(x, y, z))

## Возвращает все позиции, занимаемые объектом
func get_occupied_positions() -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	for relative_pos in relative_cells:
		positions.append(origin + relative_pos)
	return positions

## Проверяет, занимает ли объект указанную позицию
func occupies_position(pos: Vector3i) -> bool:
	return pos in get_occupied_positions()

## Устанавливает позицию объекта
func set_position(new_origin: Vector3i):
	origin = new_origin

## Возвращает размер объекта с учетом поворота
func get_rotated_size() -> Vector3i:
	if rotation == 0 or rotation == 180:
		return size
	else:
		return Vector3i(size.z, size.y, size.x)

## Клонирует объект
func clone() -> BuildObject:
	var new_object = BuildObject.new()
	new_object.origin = origin
	new_object.size = size
	new_object.relative_cells = relative_cells.duplicate()
	new_object.rotation = rotation
	new_object.object_id = object_id
	new_object.display_name = display_name
	new_object.mesh = mesh
	new_object.icon = icon
	new_object.is_interactable = is_interactable
	new_object.priority = priority
	new_object.tags = tags.duplicate()
	new_object.build_cost = build_cost.duplicate()
	new_object.build_time = build_time
	return new_object

## Инициализация из данных объекта
func init_from_data(data: BuildObjectData):
	object_id = data.id
	display_name = data.name
	mesh = data.mesh
	size = data.size
	icon = data.icon
	is_interactable = data.is_interactable
	priority = data.priority
	tags = data.tags.duplicate()
	build_cost = data.build_cost.duplicate()
	build_time = data.build_time
	_update_relative_cells()

## Обновляет прогресс строительства
func update_build_progress(delta: float):
	if not is_built:
		build_progress += delta / build_time
		if build_progress >= 1.0:
			build_progress = 1.0
			is_built = true
			_on_build_complete()

## Вызывается при завершении строительства
func _on_build_complete():
	pass

## Возвращает процент завершения строительства
func get_build_percentage() -> float:
	return build_progress * 100.0 
