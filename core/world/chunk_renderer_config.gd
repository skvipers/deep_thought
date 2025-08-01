extends Resource
class_name ChunkRendererConfig

@export var overlay_shader_path: String = "res://addons/deep_thought/shaders/overlay_shader.gdshader"
@export var grass_texture_path: String = "res://addons/deep_thought/data/resources/textures/grass_top.png"

# Конфигурация оверлеев
@export var overlay_textures: Dictionary = {
	1: "res://addons/deep_thought/data/resources/textures/leaves_transparent.png",
	2: "res://addons/deep_thought/data/resources/textures/track_straight.png", 
	3: "res://addons/deep_thought/data/resources/textures/grass_top.png"
}

# Настройки атласа оверлеев
@export var overlay_atlas_size: int = 512
@export var overlay_tile_size: int = 128
@export var overlay_atlas_tiles: int = 4

# Маппинг типов оверлеев на индексы
@export var overlay_type_to_index: Dictionary = {
	"GRASS": 0,
	"MOSS": 1, 
	"SNOW": 2
}

func get_overlay_shader() -> Shader:
	if ResourceLoader.exists(overlay_shader_path):
		return load(overlay_shader_path)
	Logger.error("ChunkRendererConfig", "Overlay shader not found at: " + overlay_shader_path)
	return null

func get_grass_texture() -> Texture2D:
	if ResourceLoader.exists(grass_texture_path):
		return load(grass_texture_path)
	Logger.error("ChunkRendererConfig", "Grass texture not found at: " + grass_texture_path)
	return null

func get_overlay_texture(index) -> Texture2D:
	# Поддерживаем как int, так и String ключи для обратной совместимости
	var key = index
	if index is String:
		key = index.to_int()
	
	if overlay_textures.has(key):
		var path = overlay_textures[key]
		if ResourceLoader.exists(path):
			return load(path)
		Logger.error("ChunkRendererConfig", "Overlay texture not found at: " + path)
	return null

func get_overlay_type_index(overlay_type: String) -> int:
	return overlay_type_to_index.get(overlay_type, 0) 