class_name BuildGrid
extends Resource

## Компонент, отвечающий за размещение строительных объектов в пространстве

@export var main_grid: Dictionary = {}  ## Dictionary<Vector3i, BuildCell>
@export var grid_size: Vector3i = Vector3i(100, 10, 100)
@export var origin: Vector3i = Vector3i.ZERO

## Сигналы
signal object_placed(pos: Vector3i, object: BuildObject)
signal object_removed(pos: Vector3i, object: BuildObject)
signal grid_cleared

## Размещает объект в указанной позиции
func place_object(pos: Vector3i, object: BuildObject) -> bool:
	if not _is_valid_position(pos):
		return false
	
	# Проверяем, что все ячейки свободны
	var occupied_positions = object.get_occupied_positions()
	for occupied_pos in occupied_positions:
		if not _is_valid_position(occupied_pos):
			return false
		if _has_object_at(occupied_pos):
			return false
	
	# Размещаем объект
	object.set_position(pos)
	
	# Создаем ячейки если нужно
	for occupied_pos in occupied_positions:
		if not main_grid.has(occupied_pos):
			main_grid[occupied_pos] = BuildCell.new()
		
		# Размещаем объект в ячейке
		var relative_pos = occupied_pos - pos
		main_grid[occupied_pos].place_object(object, relative_pos)
		object.grid_cell = main_grid[occupied_pos]
	
	object_placed.emit(pos, object)
	return true

## Удаляет объект из указанной позиции
func erase_object(pos: Vector3i) -> bool:
	if not _is_valid_position(pos):
		return false
	
	var cell = main_grid.get(pos, null)
	if cell == null or cell.is_empty():
		return false
	
	var object = cell.get_object()
	if object == null:
		return false
	
	# Удаляем объект из всех занимаемых позиций
	var occupied_positions = object.get_occupied_positions()
	for occupied_pos in occupied_positions:
		if main_grid.has(occupied_pos):
			var relative_pos = occupied_pos - pos
			main_grid[occupied_pos].remove_object(relative_pos)
			
			# Удаляем пустые ячейки
			if main_grid[occupied_pos].is_empty():
				main_grid.erase(occupied_pos)
	
	object_removed.emit(pos, object)
	return true

## Получает объект в указанной позиции
func get_object(pos: Vector3i) -> BuildObject:
	if not _is_valid_position(pos):
		return null
	
	var cell = main_grid.get(pos, null)
	if cell == null:
		return null
	
	return cell.get_object()

## Проверяет, есть ли объект в указанной позиции
func has_object_at(pos: Vector3i) -> bool:
	return _has_object_at(pos)

## Проверяет, свободна ли позиция
func is_position_free(pos: Vector3i) -> bool:
	if not _is_valid_position(pos):
		return false
	return not _has_object_at(pos)

## Проверяет, можно ли разместить объект в указанной позиции
func can_place_object(pos: Vector3i, size: Vector3i) -> bool:
	if not _is_valid_position(pos):
		return false
	
	# Проверяем все позиции, которые займет объект
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				var check_pos = pos + Vector3i(x, y, z)
				if not _is_valid_position(check_pos) or _has_object_at(check_pos):
					return false
	
	return true

## Очищает всю сетку
func clear_grid():
	main_grid.clear()
	grid_cleared.emit()

## Возвращает все объекты в сетке
func get_all_objects() -> Array[BuildObject]:
	var objects: Array[BuildObject] = []
	var processed_objects: Array[BuildObject] = []
	
	for cell in main_grid.values():
		for object in cell.get_all_objects():
			if not object in processed_objects:
				objects.append(object)
				processed_objects.append(object)
	
	return objects

## Возвращает объекты в указанном диапазоне
func get_objects_in_range(min_pos: Vector3i, max_pos: Vector3i) -> Array[BuildObject]:
	var objects: Array[BuildObject] = []
	var processed_objects: Array[BuildObject] = []
	
	for pos in main_grid.keys():
		if pos.x >= min_pos.x and pos.x <= max_pos.x and \
		   pos.y >= min_pos.y and pos.y <= max_pos.y and \
		   pos.z >= min_pos.z and pos.z <= max_pos.z:
			
			var cell = main_grid[pos]
			for object in cell.get_all_objects():
				if not object in processed_objects:
					objects.append(object)
					processed_objects.append(object)
	
	return objects

## Устанавливает размер сетки
func set_grid_size(new_size: Vector3i):
	grid_size = new_size

## Устанавливает начало координат сетки
func set_origin(new_origin: Vector3i):
	origin = new_origin

## Возвращает размер сетки
func get_grid_size() -> Vector3i:
	return grid_size

## Привязывает позицию к сетке
func snap_to_grid(world_position: Vector3) -> Vector3i:
	return Vector3i(
		round(world_position.x),
		round(world_position.y),
		round(world_position.z)
	)

## Преобразует позицию сетки в мировые координаты
func grid_to_world(grid_position: Vector3i) -> Vector3:
	return Vector3(grid_position.x, grid_position.y, grid_position.z)

## Проверяет, что позиция находится в пределах сетки
func _is_valid_position(pos: Vector3i) -> bool:
	return pos.x >= origin.x and pos.x < origin.x + grid_size.x and \
		   pos.y >= origin.y and pos.y < origin.y + grid_size.y and \
		   pos.z >= origin.z and pos.z < origin.z + grid_size.z

## Проверяет, есть ли объект в указанной позиции
func _has_object_at(pos: Vector3i) -> bool:
	var cell = main_grid.get(pos, null)
	return cell != null and not cell.is_empty() 
