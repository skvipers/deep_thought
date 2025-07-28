# Biome.gd
extends Resource
class_name Biome

@export var biome_id: String
@export var name: String = ""
@export var description: String = ""
@export var color: Color = Color.MAGENTA

@export_range(0.0, 1.0, 0.01) var frequency: float = 1.0
@export_range(1, 100, 1) var size: int = 10

## Optional generator-specific config for use by terrain generators
@export var generator_config: Dictionary = {
	"top_layer_block": "dirt",
	"surface_block": "dirt",
	"subsoil_block": "stone",
	"surface_depth": 1,
	"subsoil_depth": 10,
	"surface_level": 32
}

@export var noise_override: Dictionary = {
	"frequency": 0.01,
	"amplitude": 1.0,
	"offset": Vector2.ZERO,
	"octaves": 3,
	"lacunarity": 2.0,
	"gain": 0.5
}
