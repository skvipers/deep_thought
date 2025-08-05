class_name BuildGridVisualizer
extends Node3D

## Визуализатор строительной сетки для отладки

var build_grid: BuildGrid
var grid_material: StandardMaterial3D
var grid_lines: Array[Node3D] = []

func _ready():
	# Создаем материал для линий сетки
	grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.5, 0.5, 1.0, 0.3)  # Полупрозрачный синий
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

## Устанавливает сетку для визуализации
func set_build_grid(grid: BuildGrid):
	build_grid = grid
	_visualize_grid()

## Визуализирует сетку
func _visualize_grid():
	# Очищаем старые линии
	for line in grid_lines:
		line.queue_free()
	grid_lines.clear()
	
	if not build_grid:
		return
	
	var grid_size = build_grid.get_grid_size()
	print("[BuildGridVisualizer] Visualizing grid with size: ", grid_size)
	
	# Создаем линии сетки (упрощенная версия)
	_create_grid_lines(grid_size)

## Создает линии сетки
func _create_grid_lines(size: Vector3i):
	# Создаем линии по X
	for x in range(0, size.x + 1, 4):  # Каждые 4 блока
		var line = _create_line(
			Vector3(x, 0, 0),
			Vector3(x, 0, size.z),
			Color(1, 0, 0, 0.5)  # Красный
		)
		grid_lines.append(line)
	
	# Создаем линии по Z
	for z in range(0, size.z + 1, 4):  # Каждые 4 блока
		var line = _create_line(
			Vector3(0, 0, z),
			Vector3(size.x, 0, z),
			Color(0, 0, 1, 0.5)  # Синий
		)
		grid_lines.append(line)

## Создает линию между двумя точками
func _create_line(start: Vector3, end: Vector3, color: Color) -> Node3D:
	var line = Node3D.new()
	add_child(line)
	
	var mesh_instance = MeshInstance3D.new()
	line.add_child(mesh_instance)
	
	# Создаем примитивную линию
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.05, 0.05, start.distance_to(end))
	mesh_instance.mesh = mesh
	
	# Позиционируем линию
	line.position = (start + end) / 2
	line.look_at(end, Vector3.UP)
	
	# Применяем материал
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	
	return line

## Показывает/скрывает визуализацию
func set_visible(visible: bool):
	for line in grid_lines:
		line.visible = visible 
