extends Resource
class_name GenerationContext

@export var seed: int
@export var tile: Resource
@export var presets: Array[GeneratorPreset]
@export var generators: Array[ChunkGenerationModule]
@export var global_parameters: Dictionary
@export var block_library: BlockLibrary
