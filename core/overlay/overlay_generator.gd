extends Node
class_name OverlayGenerator

var overlay_manager: OverlayManager
var noise: FastNoiseLite

func _init(manager: OverlayManager):
	overlay_manager = manager
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.1

func generate_natural_overlays(chunk_coords: Vector3i, chunk_size: Vector3i):
	generate_grass(chunk_coords, chunk_size)
	generate_moss(chunk_coords, chunk_size)
	generate_snow_on_peaks(chunk_coords, chunk_size)

func generate_grass(chunk_coords: Vector3i, chunk_size: Vector3i):
	for x in range(chunk_size.x):
		for z in range(chunk_size.z):
			var world_x = chunk_coords.x * chunk_size.x + x
			var world_z = chunk_coords.z * chunk_size.z + z
			
			# Используем шум для определения плотности травы
			var grass_density = noise.get_noise_2d(world_x, world_z)
			grass_density = (grass_density + 1.0) / 2.0  # Нормализуем 0-1
			
			if grass_density > 0.3:  # Порог появления травы
				# Ищем верхний блок в чанке
				for y in range(chunk_size.y - 1, -1, -1):
					var local_pos = Vector3i(x, y, z)
					var world_pos = chunk_coords * chunk_size + local_pos
					
					# Проверяем, есть ли блок и подходит ли он для травы
					if overlay_manager.world_base.has_block_at(world_pos):
						overlay_manager.add_overlay_at(
							world_pos,
							BlockOverlay.OverlayType.GRASS,
							grass_density,
							BlockOverlay.Direction.UP
						)
						break

func generate_moss(chunk_coords: Vector3i, chunk_size: Vector3i):
	# Мох растет на северных стенах во влажных местах
	noise.frequency = 0.05
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			for z in range(chunk_size.z):
				var world_pos = chunk_coords * chunk_size + Vector3i(x, y, z)
				var humidity = noise.get_noise_3d(world_pos.x, world_pos.y, world_pos.z)
				humidity = (humidity + 1.0) / 2.0
				
				if humidity > 0.6:  # Высокая влажность
					overlay_manager.add_overlay_at(
						world_pos,
						BlockOverlay.OverlayType.MOSS,
						humidity * 0.7,
						BlockOverlay.Direction.NORTH
					)

func generate_snow_on_peaks(chunk_coords: Vector3i, chunk_size: Vector3i):
	# Снег на высоких местах
	var snow_line = 50  # Высота снеговой линии
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			for z in range(chunk_size.z):
				var world_y = chunk_coords.y * chunk_size.y + y
				if world_y > snow_line:
					var world_pos = chunk_coords * chunk_size + Vector3i(x, y, z)
					var snow_strength = min(1.0, (world_y - snow_line) / 20.0)
					overlay_manager.add_overlay_at(
						world_pos,
						BlockOverlay.OverlayType.SNOW,
						snow_strength,
						BlockOverlay.Direction.UP
					)
