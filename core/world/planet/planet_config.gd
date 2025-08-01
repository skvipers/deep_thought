class_name PlanetConfig
extends Resource

@export var name: String
@export var radius: float = 5.0
@export var subdivisions: int = 3
@export var seed_string: String = "default"
@export var seed: int = 0  # Автоматически вычисляется из seed_string

@export var biomes: Array[Biome] = []  # Правила присваивания биомов

# Функция для преобразования строки в числовой seed
func get_seed() -> int:
	if seed_string.is_empty():
		return 0
	
	var hash_value = 0
	for i in range(seed_string.length()):
		hash_value = ((hash_value << 5) - hash_value + seed_string.unicode_at(i)) & 0xFFFFFFFF
	
	return hash_value

# Функция для установки seed_string и автоматического обновления seed
func set_seed_string(new_seed: String):
	seed_string = new_seed
	seed = get_seed()
	print("PlanetConfig: Set seed_string to '", seed_string, "', computed seed: ", seed)
