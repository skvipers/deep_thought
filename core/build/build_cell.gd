class_name BuildCell
extends Resource

## Ячейка сетки строительства

@export var subdivisions: int = 1  ## Уровень вложенности (1, 2, 4)
@export var subgrid: Dictionary = {}  ## Dictionary[Vector3i, BuildObject] - создаётся по мере необходимости
@export var main_object: BuildObject  ## Основной объект в ячейке

## Проверяет, свободна ли ячейка
func is_empty() -> bool:
	return main_object == null and subgrid.is_empty()

## Размещает объект в ячейке
func place_object(object: BuildObject, sub_position: Vector3i = Vector3i.ZERO):
	if sub_position == Vector3i.ZERO:
		main_object = object
	else:
		if subgrid.is_empty():
			subgrid = {}
		subgrid[sub_position] = object

## Удаляет объект из ячейки
func remove_object(sub_position: Vector3i = Vector3i.ZERO):
	if sub_position == Vector3i.ZERO:
		main_object = null
	else:
		subgrid.erase(sub_position)
		if subgrid.is_empty():
			subgrid = {}

## Получает объект из ячейки
func get_object(sub_position: Vector3i = Vector3i.ZERO) -> BuildObject:
	if sub_position == Vector3i.ZERO:
		return main_object
	else:
		return subgrid.get(sub_position, null)

## Проверяет, есть ли объект в указанной подпозиции
func has_object_at(sub_position: Vector3i = Vector3i.ZERO) -> bool:
	if sub_position == Vector3i.ZERO:
		return main_object != null
	else:
		return subgrid.has(sub_position)

## Возвращает все объекты в ячейке
func get_all_objects() -> Array[BuildObject]:
	var objects: Array[BuildObject] = []
	if main_object != null:
		objects.append(main_object)
	for object in subgrid.values():
		objects.append(object)
	return objects 
