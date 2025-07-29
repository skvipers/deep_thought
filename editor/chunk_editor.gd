extends Node3D
class_name ChunkEditor

const TAG := "ChunkEditor"
const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@export var edit_enabled: bool = true
@export var edit_block_id: int = 2  # 2 = stone
@export var reach_distance: float = 100.0

var camera: Camera3D

func _ready():
	Logger.info("EDITOR", "[%s] ChunkEditor готов" % TAG)
	# Ждем один кадр чтобы камера инициализировалась
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()
	if camera:
		Logger.info("EDITOR", "[%s] Камера найдена: %s" % [TAG, camera.name])
	else:
		Logger.error("EDITOR", "[%s] ОШИБКА: Камера не найдена!" % TAG)

func _unhandled_input(event):
	if not edit_enabled:
		return
		
	if not camera:
		camera = get_viewport().get_camera_3d()
		if not camera:
			Logger.warn("EDITOR", "[%s] Камера все еще не найдена" % TAG)
			return
	
	# Отладка - выводим все клики
	if event is InputEventMouseButton and event.pressed:
		Logger.debug("EDITOR", "[%s] Клик мыши: кнопка %d в позиции %s" % [TAG, event.button_index, event.position])
	
	# ЛКМ - добавить блок
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Logger.debug("EDITOR", "[%s] ЛКМ нажата" % TAG)
		handle_block_placement(event.position)
		get_viewport().set_input_as_handled()
	
	# ПКМ - удалить блок
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		Logger.debug("EDITOR", "[%s] ПКМ нажата" % TAG)
		handle_block_removal(event.position)
		get_viewport().set_input_as_handled()

func handle_block_placement(mouse_pos: Vector2):
	Logger.debug("EDITOR", "[%s] Пытаемся разместить блок..." % TAG)
	var result = cast_ray(mouse_pos)
	
	if not result or result.is_empty():
		Logger.debug("EDITOR", "[%s] Луч не попал ни во что" % TAG)
		return
	
	Logger.debug("EDITOR", "[%s] Луч попал в: %s" % [TAG, result.collider])
	
	# Получаем позицию, куда нужно поставить блок
	var hit_position = result.position
	var hit_normal = result.normal
	
	# Находим чанк
	var chunk = find_chunk_from_collider(result.collider)
	if not chunk:
		Logger.error("EDITOR", "[%s] ОШИБКА: Не удалось найти чанк" % TAG)
		return
	
	Logger.debug("EDITOR", "[%s] Найден чанк: %s" % [TAG, chunk.name])
	
	# Вычисляем позицию нового блока
	var world_block_pos = hit_position + hit_normal * 0.5
	var local_pos = chunk.to_local(world_block_pos)
	var block_pos = Vector3i(floor(local_pos.x), floor(local_pos.y), floor(local_pos.z))
	
	Logger.debug("EDITOR", "[%s] Позиция блока: %s" % [TAG, block_pos])
	
	# Проверяем, что позиция внутри чанка
	if is_position_in_chunk(block_pos, chunk.renderer.chunk_size):
		chunk.renderer.add_block(block_pos, edit_block_id)
		Logger.info("EDITOR", "[%s] Блок добавлен!" % TAG)
	else:
		Logger.warn("EDITOR", "[%s] Позиция вне чанка: %s" % [TAG, block_pos])

func handle_block_removal(mouse_pos: Vector2):
	Logger.debug("EDITOR", "[%s] Пытаемся удалить блок..." % TAG)
	var result = cast_ray(mouse_pos)
	
	if not result or result.is_empty():
		Logger.debug("EDITOR", "[%s] Луч не попал ни во что" % TAG)
		return
	
	var hit_position = result.position
	var hit_normal = result.normal
	
	var chunk = find_chunk_from_collider(result.collider)
	if not chunk:
		Logger.error("EDITOR", "[%s] ОШИБКА: Не удалось найти чанк" % TAG)
		return
	
	# Вычисляем позицию блока для удаления
	var world_block_pos = hit_position - hit_normal * 0.5
	var chunk_origin = chunk.position
	var local_pos = chunk.to_local(world_block_pos)
	var block_pos = Vector3i(floor(local_pos.x), floor(local_pos.y), floor(local_pos.z))

	chunk.renderer.remove_block(block_pos)
	Logger.debug(TAG, "Removed block at %s" % str(block_pos))

func cast_ray(mouse_pos: Vector2) -> Dictionary:
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	Logger.debug("EDITOR", "[%s] Луч: origin=%s, direction=%s" % [TAG, ray_origin, ray_direction])
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		ray_origin, 
		ray_origin + ray_direction * reach_distance
	)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result:
		Logger.debug("EDITOR", "[%s] Луч попал в объект на расстоянии: %s" % [TAG, ray_origin.distance_to(result.position)])
	
	return result

func find_chunk_from_collider(collider: Node) -> Chunk:
	Logger.debug("EDITOR", "[%s] Ищем чанк от коллайдера: %s" % [TAG, collider.get_path()])
	
	# Выводим иерархию для отладки
	var current = collider
	var depth = 0
	while current and depth < 10:
		Logger.debug("EDITOR", "[%s]   %s-> %s (%s)" % [TAG, "  ".repeat(depth), current.name, current.get_class()])
		current = current.get_parent()
		depth += 1
	
	# Ищем Chunk вверх по иерархии
	current = collider
	while current:
		if current is Chunk:
			Logger.debug("EDITOR", "[%s] Найден Chunk: %s" % [TAG, current.name])
			return current
		current = current.get_parent()
	
	Logger.warn("EDITOR", "[%s] Chunk не найден в иерархии" % TAG)
	return null

func is_position_in_chunk(pos: Vector3i, chunk_size: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < chunk_size.x and \
		   pos.y >= 0 and pos.y < chunk_size.y and \
		   pos.z >= 0 and pos.z < chunk_size.z
