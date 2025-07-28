class_name PlanetConfig
extends Resource

@export var name: String
@export var radius: float = 5.0
@export var subdivisions: int = 3
@export var seed: int = 0

@export var biomes: Array[Biome] = []  # Правила присваивания биомов
