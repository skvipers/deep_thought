extends WorldBase
class_name WorldPreview

const TAG := "WorldPreview"
const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")
const OverlayManagerFactory = preload("res://addons/deep_thought/core/factories/OverlayManagerFactory.gd")
const ChunkFactory = preload("res://addons/deep_thought/core/factories/ChunkFactory.gd")

@export var context: GenerationContext
@export var chunk_scene: PackedScene
@export var origin_position: Vector3i = Vector3i(0, 0, 0)
@export var chunk_size: Vector3i = Vector3i(16, 32, 16)
@export var chunk_range: Vector3i = Vector3i(1, 1, 1)


@export var edit_enabled: bool = false

var overlay_manager: OverlayManager

func _ready():
	Logger.info("GENERATION", "=== WORLD PREVIEW STARTED ===")
	
	if not context:
		Logger.error("GENERATION", "GenerationContext not assigned")
		return
	if not chunk_scene:
		Logger.error("GENERATION", "Chunk scene not assigned")
		return
	if not context.block_library:
		Logger.error("GENERATION", "BlockLibrary not assigned in context")
		return
	
	Logger.info("GENERATION", "Dependencies are valid")
	Logger.debug("GENERATION", "Generators: %d" % context.generators.size())
	
	# ИСПРАВЛЕНИЕ: Сначала создаем overlay_manager
	overlay_manager = OverlayManagerFactory.create_overlay_manager(self)
	add_child(overlay_manager)
	Logger.info("GENERATION", "OverlayManager created")
	
	if edit_enabled:
		# Добавляем редактор блоков глобально
		var editor = ChunkEditor.new()
		editor.name = "GlobalChunkEditor"
		add_child(editor)
		Logger.info("EDITOR", "ChunkEditor добавлен в сцену")
	
	# ПОТОМ создаем чанки (теперь overlay_manager уже существует!)
	for x in range(-chunk_range.x, chunk_range.x + 1):
		for y in range(-chunk_range.y, chunk_range.y + 1):
			for z in range(-chunk_range.z, chunk_range.z + 1):
				var chunk_pos = origin_position + Vector3i(x, y, z)
				create_chunk_at(chunk_pos)
	
	Logger.info("GENERATION", "=== WORLD PREVIEW COMPLETE ===")

func create_chunk_at(chunk_pos: Vector3i):
	Logger.info("GENERATION", "Generating chunk at %s" % str(chunk_pos))
	
	var buffer := MapBuffer.new()
	
	for i in range(context.generators.size()):
		var generator = context.generators[i]
		if not generator:
			Logger.warn("GENERATION", "Generator #%d is null, skipping" % i)
			continue
			
		Logger.debug("GENERATION", "Running generator #%d at %s" % [i, str(chunk_pos)])
		generator.generate_chunk(buffer, context, chunk_pos, chunk_size)
	
	if buffer.get_block_positions().size() == 0:
		Logger.warn("GENERATION", "Chunk %s buffer is empty, inserting test blocks" % str(chunk_pos))
		# Вставляем тестовые блоки
		for x in range(chunk_size.x):
			for z in range(chunk_size.z):
				buffer.set_block(Vector3i(x, 0, z), 1)  # Блок типа 1 (земля)
	
	const ChunkFactory = preload("res://addons/deep_thought/core/factories/ChunkFactory.gd")
	var chunk = ChunkFactory.create_chunk(chunk_scene)
	add_child(chunk)
	chunk.initialize(chunk_pos, chunk_size, buffer, context.block_library)

	# Генерируем траву/оверлеи после инициализации чанка
	apply_natural_overlays_to_chunk(chunk_pos)

	Logger.info("GENERATION", "Chunk instantiated at %s" % str(chunk_pos))

func get_chunk_at_position(world_pos: Vector3i) -> Chunk:
	# ИСПРАВЛЕНИЕ: используем floor division для правильной работы с отрицательными числами
	var chunk_coord = Vector3i(
		floor(float(world_pos.x) / float(chunk_size.x)),
		floor(float(world_pos.y) / float(chunk_size.y)), 
		floor(float(world_pos.z) / float(chunk_size.z))
	)
	
	#Logger.debug("WorldPreview", "World pos %s -> Chunk coord %s" % [str(world_pos), str(chunk_coord)])
	
	# Ищем чанк среди детей
	for child in get_children():
		if child is Chunk and child.get_chunk_position() == chunk_coord:
			return child
	
	Logger.debug("WorldPreview", "Chunk not found for coord %s" % str(chunk_coord))
	return null

func get_overlay_manager() -> OverlayManager:
	return overlay_manager

func get_chunk_size() -> Vector3i:
	return chunk_size

func has_block_at(world_pos: Vector3i) -> bool:
	var chunk = get_chunk_at_position(world_pos)
	if not chunk:
		return false
	
	var chunk_world_start = chunk.get_chunk_position() * chunk_size
	var local_pos = world_pos - chunk_world_start
	
	# Проверка границ
	if (local_pos.x < 0 or local_pos.x >= chunk_size.x or
		local_pos.y < 0 or local_pos.y >= chunk_size.y or
		local_pos.z < 0 or local_pos.z >= chunk_size.z):
		return false
	
	return chunk.has_block_at(local_pos)


func get_block_at(world_pos: Vector3i) -> BlockType:
	var chunk = get_chunk_at_position(world_pos)
	if not chunk:
		Logger.debug("WorldPreview", "No chunk found for world_pos %s" % str(world_pos))
		return null
	
	var chunk_world_start = chunk.get_chunk_position() * chunk_size
	var local_pos = world_pos - chunk_world_start
	
	# ПРОВЕРКА: локальные координаты должны быть в пределах чанка
	if (local_pos.x < 0 or local_pos.x >= chunk_size.x or
		local_pos.y < 0 or local_pos.y >= chunk_size.y or
		local_pos.z < 0 or local_pos.z >= chunk_size.z):
		Logger.error("WorldPreview", "Calculated local_pos %s is outside chunk bounds %s for world_pos %s" % [
			str(local_pos), str(chunk_size), str(world_pos)
		])
		return null
	
	return chunk.get_block_at(local_pos)

func get_chunk_at(world_pos: Vector3i) -> Chunk:
	"""Альтернативный метод для совместимости с OverlayManager"""
	return get_chunk_at_position(world_pos)
	
func apply_natural_overlays_to_chunk(chunk_pos: Vector3i):
	"""Применяет естественные оверлеи к только что созданному чанку"""
	if overlay_manager:
		overlay_manager.apply_natural_overlays_to_chunk(chunk_pos)
