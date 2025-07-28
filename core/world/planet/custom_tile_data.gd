extends Resource
class_name CustomTileData

@export var biome: Biome

var center: Vector3
var neighbors: Array = []
var type: String = "Land"  # Или "Ocean"
var biome_id: String = "unknown"
