extends Resource
class_name BlockOverlayState

var overlay1_type: int = 0
var overlay1_strength: float = 0.0
var overlay1_direction: int = 0

var overlay2_type: int = 0  
var overlay2_strength: float = 0.0
var overlay2_direction: int = 0

var grass_strength: float = 0.0
var grass_direction: int = BlockOverlay.Direction.UP

var biome_modifier: int = 0  # Для продвинутого режима

func pack_to_color() -> Color:
	var color = Color()
	
	# R канал: трава (4 бита сила) + биом модификатор (4 бита)
	var grass_packed = int(grass_strength * 15.0) << 4
	grass_packed |= biome_modifier & 0x0F
	color.r = float(grass_packed) / 255.0
	
	# G канал: оверлей 1 (4 бита тип) + сила (4 бита)
	var overlay1_packed = (overlay1_type & 0x0F) << 4
	overlay1_packed |= int(overlay1_strength * 15.0) & 0x0F
	color.g = float(overlay1_packed) / 255.0
	
	# B канал: оверлей 2 (4 бита тип) + сила (4 бита)
	var overlay2_packed = (overlay2_type & 0x0F) << 4
	overlay2_packed |= int(overlay2_strength * 15.0) & 0x0F
	color.b = float(overlay2_packed) / 255.0
	
	# A канал: направления (3+3+2 бита)
	var directions_packed = (grass_direction & 0x07) << 5
	directions_packed |= (overlay1_direction & 0x07) << 2
	directions_packed |= (overlay2_direction & 0x03)
	color.a = float(directions_packed) / 255.0
	
	return color

func add_overlay(type: int, strength: float, direction: int = 0):
	"""Добавляет оверлей с учетом приоритетов и совместимости"""
	
	# Трава обрабатывается отдельно
	if type == 1:  # GRASS
		grass_strength = max(grass_strength, strength)
		grass_direction = direction
		return
	
	# Проверяем совместимость (можно расширить логику)
	if not can_add_overlay_type(type):
		return
	
	# Для других оверлеев используем слоты overlay1 и overlay2
	if overlay1_type == 0 or overlay1_type == type:
		# Первый слот свободен или тот же тип
		overlay1_type = type
		overlay1_strength = max(overlay1_strength, strength) if overlay1_type == type else strength
		overlay1_direction = direction
	elif overlay2_type == 0 or overlay2_type == type:
		# Второй слот свободен или тот же тип
		overlay2_type = type
		overlay2_strength = max(overlay2_strength, strength) if overlay2_type == type else strength
		overlay2_direction = direction
	else:
		# Оба слота заняты, заменяем более слабый
		if strength > overlay1_strength:
			# Сдвигаем первый во второй, новый в первый
			overlay2_type = overlay1_type
			overlay2_strength = overlay1_strength
			overlay2_direction = overlay1_direction
			overlay1_type = type
			overlay1_strength = strength
			overlay1_direction = direction
		elif strength > overlay2_strength:
			# Заменяем второй
			overlay2_type = type
			overlay2_strength = strength
			overlay2_direction = direction


func remove_overlay(overlay_type: int):
	"""Удаляет оверлей определенного типа"""
	if overlay_type == 1:  # GRASS
		grass_strength = 0.0
	elif overlay_type == overlay1_type:
		overlay1_type = 0
		overlay1_strength = 0.0
		overlay1_direction = 0
	elif overlay_type == overlay2_type:
		overlay2_type = 0
		overlay2_strength = 0.0
		overlay2_direction = 0

func has_overlay(overlay_type: int) -> bool:
	"""Проверяет есть ли оверлей определенного типа"""
	if overlay_type == 1:  # GRASS
		return grass_strength > 0.01
	elif overlay_type == overlay1_type:
		return overlay1_strength > 0.01
	elif overlay_type == overlay2_type:
		return overlay2_strength > 0.01
	return false

func has_any_overlay() -> bool:
	"""Проверяет есть ли хотя бы один оверлей"""
	return (grass_strength > 0.01 or 
			overlay1_strength > 0.01 or 
			overlay2_strength > 0.01)

func get_total_coverage() -> float:
	"""Возвращает общее покрытие оверлеями (0.0 - 1.0)"""
	return min(1.0, grass_strength + overlay1_strength + overlay2_strength)

func get_dominant_overlay_type() -> int:
	"""Возвращает тип доминирующего оверлея"""
	var max_strength = grass_strength
	var dominant_type = 1 if grass_strength > 0.01 else 0
	
	if overlay1_strength > max_strength:
		max_strength = overlay1_strength
		dominant_type = overlay1_type
	
	if overlay2_strength > max_strength:
		dominant_type = overlay2_type
	
	return dominant_type

func get_strongest_overlay() -> Dictionary:
	"""Возвращает информацию о самом сильном оверлее"""
	var strongest = {"type": 0, "strength": 0.0, "direction": 0}
	
	if grass_strength > strongest.strength:
		strongest = {"type": 1, "strength": grass_strength, "direction": grass_direction}
	
	if overlay1_strength > strongest.strength:
		strongest = {"type": overlay1_type, "strength": overlay1_strength, "direction": overlay1_direction}
	
	if overlay2_strength > strongest.strength:
		strongest = {"type": overlay2_type, "strength": overlay2_strength, "direction": overlay2_direction}
	
	return strongest

func clear_all():
	"""Очищает все оверлеи"""
	grass_strength = 0.0
	grass_direction = 0
	overlay1_type = 0
	overlay1_strength = 0.0
	overlay1_direction = 0
	overlay2_type = 0
	overlay2_strength = 0.0
	overlay2_direction = 0
	biome_modifier = 0

func can_add_overlay_type(overlay_type: int) -> bool:
	"""Проверяет можно ли добавить данный тип оверлея"""
	# Базовая логика совместимости
	# Можно расширить используя BlockOverlay.can_overlay_exist_with()
	
	# Например, снег и трава несовместимы
	if overlay_type == 3 and grass_strength > 0.5:  # Снег поверх сильной травы
		return false
	
	# Вода несовместима с пылью
	if overlay_type == 6 and (overlay1_type == 5 or overlay2_type == 5):  # Вода + пыль
		return false
	
	return true

func get_debug_string() -> String:
	"""Возвращает отладочную строку с информацией об оверлеях"""
	var parts = []
	
	if grass_strength > 0.01:
		parts.append("Grass(%.2f, dir:%d)" % [grass_strength, grass_direction])
	
	if overlay1_strength > 0.01:
		parts.append("Overlay1(type:%d, %.2f, dir:%d)" % [overlay1_type, overlay1_strength, overlay1_direction])
	
	if overlay2_strength > 0.01:
		parts.append("Overlay2(type:%d, %.2f, dir:%d)" % [overlay2_type, overlay2_strength, overlay2_direction])
	
	if biome_modifier != 0:
		parts.append("Biome(+%d)" % biome_modifier)
	
	return "Overlays: " + (", ".join(parts) if parts.size() > 0 else "None")
