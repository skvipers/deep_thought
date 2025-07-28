extends Resource
class_name BlockOverlay

enum OverlayType {
	NONE = 0,
	GRASS = 1,
	MOSS = 2,
	SNOW = 3,
	LEAVES = 4,
	DUST = 5,
	WATER_PUDDLE = 6,
	BLOOD = 7,
	ASH = 8,
	ICE = 9,
	FUNGUS = 10,
	VINES = 11,
	# ... до 16
}

enum Direction {
	UP = 0,
	DOWN = 1,
	NORTH = 2,
	SOUTH = 3,
	EAST = 4,
	WEST = 5,
	ALL = 6  # Для эффектов типа взрыва
}

# Данные оверлея
@export var type: OverlayType = OverlayType.NONE
@export var texture: Texture2D
@export var normal_map: Texture2D
@export var tint_color: Color = Color.WHITE
@export var default_strength: float = 1.0

# Правила поведения
@export_group("Behavior")
@export var spreads_naturally: bool = false
@export var spread_rate: float = 0.1
@export var decay_rate: float = 0.0  # Для временных эффектов
@export var affected_by_weather: bool = true
@export var blocks_other_overlays: bool = false

# Визуальные настройки
@export_group("Visual")
@export var blend_mode: int = 0  # 0=alpha, 1=additive, 2=multiply
@export var roughness_modifier: float = 0.0
@export var metallic_modifier: float = 0.0
@export var emission_strength: float = 0.0  # Для светящихся оверлеев

# Статические данные для всех типов
static var overlay_data: Dictionary = {
	OverlayType.GRASS: {
		"name": "Grass",
		"preferred_directions": [Direction.UP],
		"incompatible_with": [OverlayType.SNOW, OverlayType.ICE]
	},
	OverlayType.MOSS: {
		"name": "Moss", 
		"preferred_directions": [Direction.NORTH],
		"growth_conditions": ["humidity > 0.6"]
	},
	# и так далее...
}

# Методы для работы
static func can_overlay_exist_with(type1: OverlayType, type2: OverlayType) -> bool:
	var data1 = overlay_data.get(type1, {})
	var incompatible = data1.get("incompatible_with", [])
	return type2 not in incompatible

static func get_overlay_priority(type: OverlayType) -> int:
	# Снег поверх листьев, вода поверх пыли и т.д.
	match type:
		OverlayType.WATER_PUDDLE: return 10
		OverlayType.SNOW: return 9
		OverlayType.ICE: return 8
		OverlayType.LEAVES: return 5
		OverlayType.MOSS: return 3
		_: return 1
