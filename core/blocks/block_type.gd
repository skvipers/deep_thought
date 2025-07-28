extends Resource
class_name BlockType

var id: int = -1
@export var name: String = "Unnamed Block"
@export var texture: Texture2D
@export var is_solid: bool = true
@export var is_transparent: bool = false
@export var color: Color = Color(1, 1, 1)

# Система слоев
@export_group("Layer System")
@export var allow_grass_overlay: bool = false
@export var is_surface_candidate: bool = false
@export var allowed_overlays: Array[int] = [] # ID разрешенных оверлеев
@export var natural_overlay_chance: float = 0.0 # Шанс естественного появления
@export var overlay_anchor_points: int = 0 # Битовая маска куда крепятся слои

# Правила смешивания
@export_group("Blending Rules")
@export var base_roughness: float = 1.0
@export var base_metallic: float = 0.0
@export var receives_shadows_through_overlays: bool = true
@export var overlay_blend_mode: int = 0 # 0 = normal, 1 = multiply, 2 = overlay

# Биомы
@export_group("Biome Settings")
@export var biome_tint_strength: float = 1.0 # Насколько сильно биом влияет
@export var seasonal_variations: bool = false # Меняется ли с сезонами

func _init(block_id: int = 0, block_name: String = "Unnamed Block", block_color: Color = Color.WHITE):
	id = block_id
	name = block_name
	color = block_color

# Хелперы для работы со слоями
func can_have_overlay(overlay_type: int) -> bool:
	return overlay_type in allowed_overlays or allowed_overlays.is_empty()

func get_overlay_strength_modifier(direction: int) -> float:
	# Например, на камне мох растет лучше с северной стороны
	if name == "Stone" and direction == BlockOverlay.Direction.NORTH:
		return 1.5
	return 1.0
