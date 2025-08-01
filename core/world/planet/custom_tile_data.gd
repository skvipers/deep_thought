extends Resource
class_name CustomTileData

@export var biome: Biome
@export var id: int = -1
@export var biome_color: Color = Color.MAGENTA
@export var neighbor_count: int = 0
@export var vertex_count: int = 0
@export var position: Vector3 = Vector3.ZERO
@export var type: String = "Land"  # Или "Ocean"
@export var biome_id: String = "unknown"

var center: Vector3
var neighbors: Array = []

# Методы для совместимости
func get_center() -> Vector3:
	return center if center != Vector3.ZERO else position

func set_center(new_center: Vector3):
	center = new_center
	position = new_center

# Метод для конвертации в Dictionary (для обратной совместимости)
func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"biome": biome,
		"biome_name": biome.name if biome else "None",
		"biome_color": biome_color,
		"position": position,
		"neighbors": neighbors,
		"neighbor_count": neighbor_count,
		"vertices": vertex_count,
		"type": type,
		"biome_id": biome_id
	}

# Метод для создания из Dictionary
static func from_dictionary(data: Dictionary) -> CustomTileData:
	var tile = CustomTileData.new()
	tile.id = data.get("id", -1)
	tile.biome = data.get("biome", null)
	tile.biome_color = data.get("biome_color", Color.MAGENTA)
	tile.position = data.get("position", Vector3.ZERO)
	tile.neighbors = data.get("neighbors", [])
	tile.neighbor_count = data.get("neighbor_count", 0)
	tile.vertex_count = data.get("vertices", 0)
	tile.type = data.get("type", "Land")
	tile.biome_id = data.get("biome_id", "unknown")
	return tile
