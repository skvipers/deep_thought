extends Resource
class_name GeneratorPreset

@export var name: StringName = "default"

## Block names in the library
@export var surface_block: StringName = "dirt"
@export var subsoil_block: StringName = "stone"
@export var top_layer_block: StringName = "sand"

## Layer depths (relative to surface level)
@export var surface_depth: int = 1
@export var subsoil_depth: int = 10
@export var surface_level: int = 32
