extends MeshInstance3D

# Сигналы для UI
signal tile_selected(tile_data: Dictionary)
signal tile_deselected()

@export_group("Planet")
@export var planet: Planet
@export var planet_root: Node3D
@export var subdivisions: int = 3
@export var radius: float = 5.0

@export_group("Camera")
@export var camera_distance: float = 15.0
@export var camera_sensitivity: float = 0.005
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 7.0
@export var max_zoom: float = 30.0

@export_group("Rendering")
@export var show_wireframe: bool = true
@export var wireframe_thickness: float = 0.02
@export var wireframe_color: Color = Color.BLACK

# Геометрия планеты
var hex_centers: PackedVector3Array = []
var hex_neighbors: Dictionary = {}
var hex_boundaries: Dictionary = {}

# Рендеринг
var wireframe_mesh_instance: MeshInstance3D
var face_to_tile: Dictionary = {}

# Взаимодействие с тайлами
var highlighted_tile_id: int = -1
var previously_highlighted_tile_id: int = -1

# Управление камерой
var camera_rotation := Vector2(0, 0)
var is_rotating := false
var last_mouse_position := Vector2()

# Отладка
var debug_spheres: Array[MeshInstance3D] = []

func _ready():
	generate_correct_sphere()
	setup_camera()

func setup_camera():
	var camera = get_viewport().get_camera_3d()
	if camera:
		# Устанавливаем начальную позицию камеры
		update_camera_position()

func update_camera_position():
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
		
	# Вычисляем позицию камеры на сфере вокруг планеты
	var pos := Vector3()
	pos.x = camera_distance * sin(camera_rotation.y) * cos(camera_rotation.x)
	pos.y = camera_distance * sin(camera_rotation.x)
	pos.z = camera_distance * cos(camera_rotation.y) * cos(camera_rotation.x)
	
	camera.position = pos
	camera.look_at(Vector3.ZERO, Vector3.UP)

func generate_correct_sphere():
	print("Генерация правильной сферы Голдберга...")

	var geometry_data = GoldbergGeometry.generate_goldberg_sphere_correct(subdivisions, radius)
	if planet:
		planet.generate(geometry_data)

	hex_centers = geometry_data.hex_centers
	hex_neighbors = geometry_data.hex_neighbors
	hex_boundaries = geometry_data.hex_boundaries

	print("Создано ", hex_centers.size(), " гексагональных тайлов")

	create_hex_visualization()

	if show_wireframe:
		create_correct_wireframe()

func create_hex_visualization():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var face_index := 0
	var vertex_count := 0
	face_to_tile.clear()

	for hex_id in hex_centers.size():
		if not hex_boundaries.has(hex_id):
			continue

		var center: Vector3 = hex_centers[hex_id]
		var boundary: PackedVector3Array = hex_boundaries[hex_id]
		if boundary.size() < 3:
			continue

		var tile_color := _get_tile_color(hex_id)
		var center_index := _add_hex_center_vertex(surface_tool, center, tile_color, vertex_count)
		vertex_count += 1

		var boundary_indices := _add_hex_boundary_vertices(surface_tool, boundary, tile_color, vertex_count)
		vertex_count += boundary_indices.size()

		_create_hex_triangles(surface_tool, center_index, boundary_indices, boundary.size(), hex_id, face_index)
		face_index += boundary.size()

	_finalize_mesh(surface_tool)
	create_sphere_collision()

func _get_tile_color(hex_id: int) -> Color:
	if planet and hex_id < planet.tiles.size():
		var tile = planet.tiles[hex_id]
		if tile.biome:
			return tile.biome.color
	return Color.MAGENTA

func _add_hex_center_vertex(surface_tool: SurfaceTool, center: Vector3, color: Color, vertex_count: int) -> int:
	surface_tool.set_normal(center.normalized())
	surface_tool.set_color(color)
	surface_tool.add_vertex(center)
	return vertex_count

func _add_hex_boundary_vertices(surface_tool: SurfaceTool, boundary: PackedVector3Array, color: Color, start_vertex_count: int) -> Array[int]:
	var indices: Array[int] = []
	var vertex_count := start_vertex_count
	
	for boundary_vertex in boundary:
		surface_tool.set_normal(boundary_vertex.normalized())
		surface_tool.set_color(color)
		surface_tool.add_vertex(boundary_vertex)
		indices.append(vertex_count)
		vertex_count += 1
	
	return indices

func _create_hex_triangles(surface_tool: SurfaceTool, center_index: int, boundary_indices: Array[int], boundary_size: int, hex_id: int, start_face_index: int):
	for i in boundary_size:
		var next_i = (i + 1) % boundary_size
		surface_tool.add_index(center_index)
		surface_tool.add_index(boundary_indices[i])
		surface_tool.add_index(boundary_indices[next_i])
		face_to_tile[start_face_index + i] = hex_id

func _finalize_mesh(surface_tool: SurfaceTool):
	var array_mesh = surface_tool.commit()
	mesh = array_mesh

	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	set_surface_override_material(0, material)

func create_sphere_collision():
	# Удаляем старую коллизию если есть
	for child in get_children():
		if child.name == "PlanetBody":
			child.queue_free()
	
	var body = StaticBody3D.new()
	body.name = "PlanetBody"
	
	var collider = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = radius
	collider.shape = sphere_shape
	collider.name = "PlanetCollider"
	
	body.add_child(collider)
	add_child(body)

func create_correct_wireframe():
	if wireframe_mesh_instance:
		wireframe_mesh_instance.queue_free()

	var line_vertices := PackedVector3Array()
	var line_indices := PackedInt32Array()
	var vertex_count := 0

	for hex_id in hex_centers.size():
		if hex_id not in hex_boundaries:
			continue

		var boundary: PackedVector3Array = hex_boundaries[hex_id]
		if boundary.size() < 3:
			continue

		for i in boundary.size():
			var current = boundary[i]
			var next = boundary[(i + 1) % boundary.size()]

			var pos1 = current.normalized() * (radius + wireframe_thickness)
			var pos2 = next.normalized() * (radius + wireframe_thickness)

			line_vertices.append(pos1)
			line_vertices.append(pos2)

			line_indices.append(vertex_count)
			line_indices.append(vertex_count + 1)
			vertex_count += 2

	_create_wireframe_mesh(line_vertices, line_indices)
	print("Создан wireframe с ", line_vertices.size() / 2.0, " линиями")

func _create_wireframe_mesh(vertices: PackedVector3Array, indices: PackedInt32Array):
	var surface_array := []
	surface_array.resize(ArrayMesh.ARRAY_MAX)
	surface_array[ArrayMesh.ARRAY_VERTEX] = vertices
	surface_array[ArrayMesh.ARRAY_INDEX] = indices

	var line_mesh = ArrayMesh.new()
	line_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, surface_array)

	wireframe_mesh_instance = MeshInstance3D.new()
	wireframe_mesh_instance.mesh = line_mesh

	var wireframe_material = StandardMaterial3D.new()
	wireframe_material.flags_unshaded = true
	wireframe_material.albedo_color = wireframe_color
	wireframe_mesh_instance.set_surface_override_material(0, wireframe_material)

	add_child(wireframe_mesh_instance)

func toggle_wireframe():
	show_wireframe = !show_wireframe
	if show_wireframe:
		create_correct_wireframe()
	elif wireframe_mesh_instance:
		wireframe_mesh_instance.queue_free()
		wireframe_mesh_instance = null

func highlight_tile_by_position(hit_position: Vector3):
	# Преобразуем точку попадания в локальное пространство планеты
	var local_hit_position = to_local(hit_position)
	
	# Проецируем точку попадания на сферу для более точного определения
	var projected_position = local_hit_position.normalized() * radius
	
	var closest_tile_id := _find_closest_tile(projected_position)
	
	if closest_tile_id >= 0:
		_update_highlighted_tile(closest_tile_id)
		_print_debug_info(hit_position, local_hit_position, projected_position, closest_tile_id)
		_emit_tile_selected_signal(closest_tile_id)
		_show_debug_visualization(local_hit_position, projected_position, closest_tile_id)
	else:
		_deselect_tile()

func _find_closest_tile(projected_position: Vector3) -> int:
	var closest_tile_id := -1
	var min_distance := INF
	
	# Находим ближайший центр тайла к проецированной точке
	for tile_id in hex_centers.size():
		var distance = hex_centers[tile_id].distance_to(projected_position)
		if distance < min_distance:
			min_distance = distance
			closest_tile_id = tile_id
	
	# Дополнительная проверка - убеждаемся что точка действительно внутри тайла
	if closest_tile_id >= 0:
		var is_inside = is_point_inside_tile(projected_position, closest_tile_id)
		if not is_inside:
			# Если точка не внутри найденного тайла, ищем среди соседей
			closest_tile_id = find_tile_containing_point(projected_position, closest_tile_id)
	
	return closest_tile_id

func _update_highlighted_tile(tile_id: int):
	# Восстанавливаем цвет предыдущего выделенного тайла
	if previously_highlighted_tile_id >= 0 and previously_highlighted_tile_id != tile_id:
		restore_tile_color(previously_highlighted_tile_id)
	
	highlighted_tile_id = tile_id
	previously_highlighted_tile_id = tile_id
	update_tile_color(tile_id, Color.YELLOW)

func _print_debug_info(hit_position: Vector3, local_hit: Vector3, projected: Vector3, tile_id: int):
	print("\n=== ОТЛАДКА ВЫБОРА ТАЙЛА ===")
	print("Мировая точка попадания:", hit_position)
	print("Локальная точка попадания:", local_hit)
	print("Проецированная точка:", projected)
	print("Выбран тайл ID:", tile_id)
	
	var distance = hex_centers[tile_id].distance_to(projected)
	print("Расстояние до центра:", distance)
	
	print_tile_info(tile_id)

func _emit_tile_selected_signal(tile_id: int):
	emit_tile_selected_signal(tile_id)

func _show_debug_visualization(local_hit: Vector3, projected: Vector3, tile_id: int):
	if OS.is_debug_build():
		show_debug_sphere(local_hit, Color.RED, 0.1)  # Красная - точка попадания
		show_debug_sphere(projected, Color.GREEN, 0.15)  # Зеленая - проекция
		show_debug_sphere(hex_centers[tile_id], Color.BLUE, 0.2)  # Синяя - центр тайла

func _deselect_tile():
	# Если тайл не найден, отправляем сигнал отмены выделения
	tile_deselected.emit()

func _handle_no_hit():
	# Отправляем сигнал отмены выделения
	tile_deselected.emit()
	# Восстанавливаем цвет предыдущего выделенного тайла
	if previously_highlighted_tile_id >= 0:
		restore_tile_color(previously_highlighted_tile_id)
		previously_highlighted_tile_id = -1
		highlighted_tile_id = -1

func emit_tile_selected_signal(tile_id: int):
	if not planet or tile_id < 0 or tile_id >= planet.tiles.size():
		return
		
	var tile = planet.tiles[tile_id]
	
	# Собираем данные тайла в словарь
	var tile_data = {
		"id": tile_id,
		"biome": tile.biome,
		"biome_name": tile.biome.name if tile.biome else "None",
		"biome_color": tile.biome.color if tile.biome else Color.MAGENTA,
		"position": hex_centers[tile_id],
		"neighbors": tile.neighbors,
		"neighbor_count": tile.neighbors.size(),
		"vertices": hex_boundaries[tile_id].size() if hex_boundaries.has(tile_id) else 0
	}
	
	# Можно добавить дополнительные данные, например:
	# "temperature": tile.temperature,
	# "humidity": tile.humidity,
	# "elevation": tile.elevation,
	# и т.д.
	
	tile_selected.emit(tile_data)

func is_point_inside_tile(point: Vector3, tile_id: int) -> bool:
	if not hex_boundaries.has(tile_id):
		return false
		
	var boundary: PackedVector3Array = hex_boundaries[tile_id]
	if boundary.size() < 3:
		return false
	
	# Для сферической геометрии проверяем угловое расстояние
	var center := hex_centers[tile_id]
	var max_angle := 0.0
	
	for vertex in boundary:
		var angle = center.angle_to(vertex)
		max_angle = max(max_angle, angle)
	
	var point_angle = center.angle_to(point)
	return point_angle <= max_angle * 1.2  # Добавляем небольшой запас

func find_tile_containing_point(point: Vector3, start_tile_id: int) -> int:
	# Проверяем стартовый тайл и его соседей
	var tiles_to_check := [start_tile_id]
	
	if planet and start_tile_id < planet.tiles.size():
		var tile = planet.tiles[start_tile_id]
		tiles_to_check.append_array(tile.neighbors)
	
	var best_tile_id := start_tile_id
	var min_distance := hex_centers[start_tile_id].distance_to(point)
	
	for tile_id in tiles_to_check:
		if tile_id < 0 or tile_id >= hex_centers.size():
			continue
			
		var distance = hex_centers[tile_id].distance_to(point)
		if distance < min_distance and is_point_inside_tile(point, tile_id):
			min_distance = distance
			best_tile_id = tile_id
	
	return best_tile_id

func show_debug_sphere(pos: Vector3, color: Color, size: float):
	# Создаем временную сферу для отладки
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radial_segments = 8
	sphere_mesh.height = size * 2
	sphere_mesh.radius = size
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = pos
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.set_surface_override_material(0, material)
	
	add_child(mesh_instance)
	debug_spheres.append(mesh_instance)
	
	# Удаляем через 2 секунды
	get_tree().create_timer(2.0).timeout.connect(func(): 
		if is_instance_valid(mesh_instance):
			mesh_instance.queue_free()
			debug_spheres.erase(mesh_instance)
	)

func restore_tile_color(tile_id: int):
	if not planet or tile_id < 0 or tile_id >= planet.tiles.size():
		return
		
	var tile = planet.tiles[tile_id]
	var original_color = Color.MAGENTA
	if tile.biome:
		original_color = tile.biome.color
	
	update_tile_color(tile_id, original_color)

func update_tile_color(tile_id: int, new_color: Color):
	var array_mesh := mesh as ArrayMesh
	if not array_mesh:
		return

	var arrays = array_mesh.surface_get_arrays(0)
	var colors: PackedColorArray = arrays[ArrayMesh.ARRAY_COLOR]
	var indices: PackedInt32Array = arrays[ArrayMesh.ARRAY_INDEX]

	# Проходим по всем граням и обновляем цвет для нужного тайла
	for face_index in face_to_tile:
		if face_to_tile[face_index] == tile_id:
			var base = face_index * 3
			for i in range(3):
				var vertex_index = indices[base + i]
				colors[vertex_index] = new_color

	arrays[ArrayMesh.ARRAY_COLOR] = colors
	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func print_tile_info(tile_id: int):
	print("\n--- ИНФОРМАЦИЯ О ТАЙЛЕ ---")
	print("ID тайла:", tile_id)
	
	if not planet or tile_id < 0 or tile_id >= planet.tiles.size():
		print("Тайл не найден или индекс вне диапазона")
		return

	var tile = planet.tiles[tile_id]
	var biome_name = "None"
	var biome_color = Color(1, 0, 1)
	if tile.biome:
		biome_name = tile.biome.name
		biome_color = tile.biome.color

	print("Биом:", biome_name)
	print("Цвет биома:", biome_color)
	print("Позиция центра:", hex_centers[tile_id])
	print("Соседи:", tile.neighbors)
	print("Количество соседей:", tile.neighbors.size())
	
	# Проверка границ
	if hex_boundaries.has(tile_id):
		var boundary = hex_boundaries[tile_id]
		print("Вершин границы:", boundary.size())
		if boundary.size() > 0:
			print("Первая вершина границы:", boundary[0])

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				toggle_wireframe()
			KEY_R:
				generate_correct_sphere()
			KEY_D:
				# Очистка отладочных сфер
				for sphere in debug_spheres:
					if is_instance_valid(sphere):
						sphere.queue_free()
				debug_spheres.clear()

	# Вращение камеры вместо вращения планеты
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_rotating = event.pressed
			last_mouse_position = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = clamp(camera_distance - zoom_speed * camera_distance, min_zoom, max_zoom)
			update_camera_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = clamp(camera_distance + zoom_speed * camera_distance, min_zoom, max_zoom)
			update_camera_position()

	elif event is InputEventMouseMotion and is_rotating:
		var delta = event.position - last_mouse_position
		last_mouse_position = event.position

		# Обновляем углы вращения камеры
		camera_rotation.x -= delta.y * camera_sensitivity
		camera_rotation.y -= delta.x * camera_sensitivity
		
		# Ограничиваем вертикальное вращение
		camera_rotation.x = clamp(camera_rotation.x, -PI/2 + 0.1, PI/2 - 0.1)
		
		update_camera_position()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var camera := get_viewport().get_camera_3d()
		if camera == null:
			print("Камера не найдена")
			return

		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000.0

		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [self]
		var result = space_state.intersect_ray(query)

		if result and result.has("position"):
			highlight_tile_by_position(result.position)
		else:
			print("Нет попадания по планете")
			_handle_no_hit()
