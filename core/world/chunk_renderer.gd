extends Node3D
class_name ChunkRenderer

const TAG := "ChunkRenderer"

@export var block_library: BlockLibrary
@export var buffer: MapBuffer
@export var chunk_size: Vector3i = Vector3i(16, 16, 16)
@export var debug_output: bool = false
@export var config: ChunkRendererConfig

var mesh_instance: MeshInstance3D
var needs_rebuild: bool = false

var overlay_states: Dictionary = {}

const DIRECTIONS = [
	Vector3i.UP,
	Vector3i.DOWN,
	Vector3i.RIGHT,
	Vector3i.LEFT,
	Vector3i.BACK,
	Vector3i.FORWARD
]

const FACE_VERTICES = [
	[Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)],
	[Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, 0)],
	[Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)],
	[Vector3(0, 0, 1), Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1)],
	[Vector3(1, 0, 1), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1)],
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0)]
]

const FACE_UVS = [
	Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)
]

func _ready():
	Logger.debug(TAG, "ChunkRenderer ready. Waiting for explicit mesh build.")

func initialize_and_build():
	Logger.debug(TAG, "initialize_and_build() called")

	if not validate_dependencies():
		return

	block_library.ensure_initialized()
	rebuild_mesh()

func set_overlay(local_pos: Vector3i, overlay_state: BlockOverlayState):
	overlay_states[local_pos] = overlay_state
	mark_for_rebuild()

func get_overlay(local_pos: Vector3i) -> BlockOverlayState:
	return overlay_states.get(local_pos, null)

func remove_overlay(local_pos: Vector3i):
	overlay_states.erase(local_pos)
	mark_for_rebuild()

func validate_dependencies() -> bool:
	if not buffer:
		Logger.error(TAG, "MapBuffer not assigned to ChunkRenderer")
		return false
	if not block_library:
		Logger.error(TAG, "BlockLibrary not assigned to ChunkRenderer")
		return false
	if not config:
		Logger.error(TAG, "ChunkRendererConfig not assigned to ChunkRenderer. This is required.")
		return false
	return true

func rebuild_mesh():
	Logger.debug(TAG, "Rebuilding mesh...")

	var blocks_by_texture: Dictionary = {}
	var blocks_processed = 0
	var solid_blocks = 0

	for pos in buffer.get_block_positions():
		blocks_processed += 1
		var block_id = buffer.get_block(pos)
		var block = block_library.get_block_by_id(block_id)
		if block == null or not block.is_solid:
			continue

		solid_blocks += 1
		var texture_key = block.texture if block.texture else block.name
		if not blocks_by_texture.has(texture_key):
			blocks_by_texture[texture_key] = {
				"blocks": [],
				"texture": block.texture,
				"color": block.color
			}
		blocks_by_texture[texture_key]["blocks"].append({"pos": pos, "block": block})

	Logger.info(TAG, "Processed %d blocks, solid: %d, texture groups: %d" % [blocks_processed, solid_blocks, blocks_by_texture.size()])

	clear_existing_meshes()
	Logger.debug(TAG, "Children after clearing: %d" % get_child_count())

	for texture_key in blocks_by_texture.keys():
		var group = blocks_by_texture[texture_key]
		create_mesh_for_texture_group(group, texture_key)

func clear_existing_meshes():
	for child in get_children():
		if child is MeshInstance3D or child is StaticBody3D:
			remove_child(child)
			child.queue_free()

func create_mesh_for_texture_group(group: Dictionary, texture_key):
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	var vertex_count = 0
	
	Logger.debug(TAG, "Creating mesh for texture '%s' with %d blocks" % [texture_key, group["blocks"].size()])
	
	var has_overlays = false
	for block_data in group["blocks"]:
		var pos = block_data["pos"]
		var block = block_data["block"]
		
		if overlay_states.has(pos):
			has_overlays = true
			
		vertex_count = add_visible_faces(pos, block, vertices, normals, uvs, colors, indices, vertex_count)
	
	
	if vertices.size() > 0:
		# Создаем ArrayMesh
		var array_mesh = ArrayMesh.new()
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
		# Создаем материал
		var material = StandardMaterial3D.new()
		if group["texture"] != null:
			material.albedo_texture = group["texture"]
		else:
			material.albedo_color = group["color"]
			material.vertex_color_use_as_albedo = true
		material.cull_mode = BaseMaterial3D.CULL_BACK
		
		if has_overlays:
			# Заменяем на шейдерный материал
			var shader_mat = ShaderMaterial.new()
			shader_mat.shader = config.get_overlay_shader()
			if group["texture"] != null:
				shader_mat.set_shader_parameter("base_texture", group["texture"])
			var grass_texture = config.get_grass_texture()
			if grass_texture:
				shader_mat.set_shader_parameter("grass_texture", grass_texture)
			
			# Временный атлас оверлеев (можно расширить позже)
			#var overlay_atlas = create_temporary_overlay_atlas(group["texture"])
			var overlay_atlas = create_overlay_atlas(group["texture"])
			shader_mat.set_shader_parameter("overlay_texture_atlas", overlay_atlas)
			
			# Градиент биомов
			var biome_gradient = create_simple_biome_gradient()
			shader_mat.set_shader_parameter("biome_colors", biome_gradient)
			
			shader_mat.set_shader_parameter("atlas_size", Vector2(4, 4))
			shader_mat.set_shader_parameter("use_simple_biome", true)
			shader_mat.set_shader_parameter("biome_id", 0)
			material = shader_mat
		else:
			if group["texture"] != null:
				material.albedo_texture = group["texture"]
			else:
				material.albedo_color = group["color"]
				material.vertex_color_use_as_albedo = true
				material.cull_mode = BaseMaterial3D.CULL_BACK
		
		# Создаем StaticBody3D для коллизий
		var static_body = StaticBody3D.new()
		static_body.collision_layer = 1
		static_body.collision_mask = 1
		
		# Создаем MeshInstance3D
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = array_mesh
		mesh_instance.material_override = material
		
		# Создаем CollisionShape3D с формой из меша
		var collision_shape = CollisionShape3D.new()
		var trimesh_shape = array_mesh.create_trimesh_shape()
		collision_shape.shape = trimesh_shape
		
		# Собираем иерархию: StaticBody3D -> MeshInstance3D + CollisionShape3D
		static_body.add_child(mesh_instance)
		static_body.add_child(collision_shape)
		
		# Добавляем к ChunkRenderer
		add_child(static_body)
		
		Logger.debug(TAG, "Mesh created with %d vertices and collision shape" % vertices.size())
		


func add_visible_faces(pos: Vector3i, block: BlockType, vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array, vertex_count: int) -> int:
	var faces_added = 0
	
	var vertex_color = block.color
	var overlay_state = overlay_states.get(pos)
	if overlay_state:
		vertex_color = overlay_state.pack_to_color()
	
	for direction_index in range(DIRECTIONS.size()):
		var direction = DIRECTIONS[direction_index]
		var neighbor_pos = pos + direction
		if should_render_face(neighbor_pos):
			add_face_geometry(pos, direction_index, vertex_color, vertices, normals, uvs, colors, indices, vertex_count + faces_added * 4)
			faces_added += 1
	return vertex_count + faces_added * 4

func should_render_face(neighbor_pos: Vector3i) -> bool:
	if not is_position_in_chunk(neighbor_pos):
		return true
	var neighbor_id = buffer.get_block(neighbor_pos)
	if neighbor_id == -1:
		return true
	var neighbor_block = block_library.get_block_by_id(neighbor_id)
	return neighbor_block == null or not neighbor_block.is_solid

func is_position_in_chunk(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < chunk_size.x and pos.y >= 0 and pos.y < chunk_size.y and pos.z >= 0 and pos.z < chunk_size.z

func add_face_geometry(pos: Vector3i, direction_index: int, color: Color, vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array, start_vertex_index: int):
	var base_pos = Vector3(pos)
	var direction_vector = Vector3(DIRECTIONS[direction_index])
	var face_vertices = FACE_VERTICES[direction_index]
	for i in range(4):
		vertices.append(base_pos + face_vertices[i])
		normals.append(direction_vector)
		uvs.append(FACE_UVS[i])
		colors.append(color)
	var v0 = start_vertex_index
	var v1 = start_vertex_index + 1
	var v2 = start_vertex_index + 2
	var v3 = start_vertex_index + 3
	indices.append_array([v0, v1, v2, v0, v2, v3])

func create_mesh_from_arrays(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array):
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_BACK
	mesh_instance.mesh = array_mesh
	mesh_instance.material_override = material

func add_block(pos: Vector3i, block_id: int):
	if not is_position_in_chunk(pos):
		Logger.warn(TAG, "Tried to add block outside chunk bounds: " + str(pos))
		return
	buffer.set_block(pos, block_id)
	mark_for_rebuild()
	if debug_output:
		Logger.debug(TAG, "Block added at %s" % str(pos))

func remove_block(pos: Vector3i):
	if not is_position_in_chunk(pos):
		Logger.warn(TAG, "Tried to remove block outside chunk bounds: " + str(pos))
		return
	buffer.set_block(pos, -1)
	mark_for_rebuild()
	if debug_output:
		Logger.debug(TAG, "Block removed from %s" % str(pos))
	Logger.debug(TAG, "Value after removal: %d" % buffer.get_block(pos))

func update_block(pos: Vector3i, new_block_id: int):
	if not is_position_in_chunk(pos):
		Logger.warn(TAG, "Tried to update block outside chunk bounds: " + str(pos))
		return
	buffer.set_block(pos, new_block_id)
	mark_for_rebuild()
	if debug_output:
		Logger.debug(TAG, "Block at %s updated to ID %d" % [str(pos), new_block_id])

func mark_for_rebuild():
	if not needs_rebuild:
		needs_rebuild = true
		call_deferred("rebuild_if_needed")

func rebuild_if_needed():
	if needs_rebuild:
		rebuild_mesh()
		needs_rebuild = false

func force_rebuild():
	needs_rebuild = false
	rebuild_mesh()

func get_block_at(pos: Vector3i) -> BlockType:
	if not is_position_in_chunk(pos):
		return null
	var block_id = buffer.get_block(pos)
	if block_id == -1:
		return null
	return block_library.get_block_by_id(block_id)

func has_block_at(pos: Vector3i) -> bool:
	var block = get_block_at(pos)
	return block != null and block.is_solid

func get_visible_faces_count() -> int:
	var count = 0
	for pos in buffer.get_block_positions():
		var block_id = buffer.get_block(pos)
		var block = block_library.get_block_by_id(block_id)
		if block == null or not block.is_solid:
			continue
		for direction in DIRECTIONS:
			if should_render_face(pos + direction):
				count += 1
	return count

func clear_all_blocks():
	for pos in buffer.get_block_positions():
		var before = buffer.get_block(pos)
		buffer.set_block(pos, -1)
		Logger.debug(TAG, "Before: %d, After: %d" % [before, buffer.get_block(pos)])
	mark_for_rebuild()
	if debug_output:
		Logger.debug(TAG, "All blocks cleared from chunk")

func get_stats() -> Dictionary:
	var total_blocks = 0
	var solid_blocks = 0
	var visible_faces = 0
	for pos in buffer.get_block_positions():
		var block_id = buffer.get_block(pos)
		if block_id != -1:
			total_blocks += 1
			var block = block_library.get_block_by_id(block_id)
			if block != null and block.is_solid:
				solid_blocks += 1
	visible_faces = get_visible_faces_count()
	return {
		"total_blocks": total_blocks,
		"solid_blocks": solid_blocks,
		"visible_faces": visible_faces,
		"triangles": visible_faces * 2,
		"vertices": visible_faces * 4
	}

func create_simple_biome_gradient() -> ImageTexture:
	"""Создает простой градиент для биомов"""
	var image = Image.create(32, 1, false, Image.FORMAT_RGB8)
	for i in range(32):
		var t = float(i) / 31.0
		# Создаем градиент от зеленого к коричневому
		var color = Color.GREEN.lerp(Color(0.6, 0.4, 0.2), t)
		image.set_pixel(i, 0, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture


func create_overlay_atlas(base_texture: Texture2D) -> ImageTexture:
	"""
	Создает атлас оверлеев с базовой текстурой блока и текстурами оверлеев
	"""
	if not base_texture:
		Logger.error(TAG, "Base texture is null for overlay atlas")
		return null
		
	var base_image = base_texture.get_image()
	if not base_image:
		Logger.error(TAG, "Failed to get image from base texture")
		return null
	
	# Подготавливаем базовую текстуру
	if base_image.is_compressed():
		base_image.decompress()
	base_image.convert(Image.FORMAT_RGBA8)
	
	# Получаем размеры из конфигурации
	var atlas_size = config.overlay_atlas_size
	var tile_size = config.overlay_tile_size
	var atlas_tiles = config.overlay_atlas_tiles
	
	# Создаем атлас
	var atlas_image = Image.create(atlas_size, atlas_size, false, Image.FORMAT_RGBA8)
	atlas_image.fill(Color(0, 0, 0, 0))  # Прозрачный фон

	Logger.debug(TAG, "Created empty overlay atlas %dx%d" % [atlas_size, atlas_size])	
	
	# Позиция 0 (верхний левый) - базовая текстура блока
	var resized_base = base_image.duplicate()
	if resized_base.get_width() != tile_size or resized_base.get_height() != tile_size:
		resized_base.resize(tile_size, tile_size)
	atlas_image.blit_rect(resized_base, Rect2i(0, 0, tile_size, tile_size), Vector2i(0, 0))
	
	Logger.debug(TAG, "Added base texture to atlas at (0, 0)")
	
	# Добавляем текстуры оверлеев
	var loaded_overlays = 0
	var overlay_textures = config.overlay_textures
	
	for overlay_index in overlay_textures.keys():
		var overlay_texture = null
		
		# Убеждаемся что индекс - это int
		var index = overlay_index
		if overlay_index is String:
			index = overlay_index.to_int()
		overlay_texture = config.get_overlay_texture(index)
		
		if not overlay_texture or not overlay_texture is Texture2D:
			Logger.warn(TAG, "Failed to load overlay texture for index: %d" % overlay_index)
			continue
		
		var overlay_image = overlay_texture.get_image()
		if not overlay_image:
			Logger.warn(TAG, "Failed to get image from overlay texture for index: %d" % overlay_index)
			continue
		
		# Подготавливаем изображение оверлея
		if overlay_image.is_compressed():
			overlay_image.decompress()
		if overlay_image.get_format() != Image.FORMAT_RGBA8:
			overlay_image.convert(Image.FORMAT_RGBA8)
		
		# Изменяем размер если нужно
		if overlay_image.get_width() != tile_size or overlay_image.get_height() != tile_size:
			overlay_image.resize(tile_size, tile_size)
		
		# Вычисляем позицию в атласе
		var atlas_x = (overlay_index % atlas_tiles) * tile_size
		var atlas_y = (overlay_index / atlas_tiles) * tile_size
		
		# Копируем в атлас
		atlas_image.blit_rect(overlay_image, Rect2i(0, 0, tile_size, tile_size), Vector2i(atlas_x, atlas_y))
		
		Logger.debug(TAG, "Added overlay texture for index %d to atlas at (%d, %d)" % [overlay_index, atlas_x, atlas_y])
		loaded_overlays += 1
	
	Logger.info(TAG, "Created overlay atlas with %d overlay textures" % loaded_overlays)
	
	var atlas_texture = ImageTexture.new()
	atlas_texture.set_image(atlas_image)
	return atlas_texture

func get_overlay_type_index(overlay_type: int) -> int:
	"""
	Возвращает индекс в атласе для типа оверлея
	"""
	# Конвертируем enum в строку для поиска в конфиге
	var overlay_type_name = ""
	match overlay_type:
		BlockOverlay.OverlayType.GRASS:
			overlay_type_name = "GRASS"
		BlockOverlay.OverlayType.MOSS:
			overlay_type_name = "MOSS"
		BlockOverlay.OverlayType.SNOW:
			overlay_type_name = "SNOW"
		_:
			overlay_type_name = "GRASS"  # По умолчанию
	
	return config.get_overlay_type_index(overlay_type_name)
