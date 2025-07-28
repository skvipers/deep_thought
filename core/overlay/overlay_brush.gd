extends Node
class_name OverlayBrush

enum BrushMode {
	PAINT,
	ERASE,
	SMOOTH,
	FLOOD_FILL
}

var current_overlay_type: BlockOverlay.OverlayType = BlockOverlay.OverlayType.GRASS
var brush_size: float = 2.0
var brush_strength: float = 1.0
var brush_mode: BrushMode = BrushMode.PAINT
var brush_direction: int = BlockOverlay.Direction.UP

var overlay_manager: OverlayManager

func _init(manager: OverlayManager):
	overlay_manager = manager

func paint_at_position(world_pos: Vector3i):
	match brush_mode:
		BrushMode.PAINT:
			paint_sphere(world_pos)
		BrushMode.ERASE:
			erase_sphere(world_pos)
		BrushMode.FLOOD_FILL:
			flood_fill(world_pos)

func paint_sphere(center: Vector3i):
	var radius_int = int(ceil(brush_size))
	for x in range(-radius_int, radius_int + 1):
		for y in range(-radius_int, radius_int + 1):
			for z in range(-radius_int, radius_int + 1):
				var offset = Vector3i(x, y, z)
				var distance = Vector3(offset).length()
				if distance <= brush_size:
					var falloff = 1.0 - (distance / brush_size)
					var final_strength = brush_strength * falloff
					overlay_manager.add_overlay_at(
						center + offset,
						current_overlay_type,
						final_strength,
						brush_direction
					)

func erase_sphere(center: Vector3i):
	var radius_int = int(ceil(brush_size))
	for x in range(-radius_int, radius_int + 1):
		for y in range(-radius_int, radius_int + 1):
			for z in range(-radius_int, radius_int + 1):
				var offset = Vector3i(x, y, z)
				var distance = Vector3(offset).length()
				if distance <= brush_size:
					overlay_manager.remove_overlay_at(center + offset, current_overlay_type)

func flood_fill(start_pos: Vector3i):
	# Простая реализация заливки
	var visited = {}
	var queue = [start_pos]
	var max_fill = 1000  # Лимит на количество блоков
	
	while queue.size() > 0 and visited.size() < max_fill:
		var pos = queue.pop_front()
		if visited.has(pos):
			continue
		
		visited[pos] = true
		overlay_manager.add_overlay_at(pos, current_overlay_type, brush_strength, brush_direction)
		
		# Добавляем соседей
		for direction in [Vector3i.UP, Vector3i.DOWN, Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
			var neighbor = pos + direction
			if not visited.has(neighbor):
				queue.append(neighbor)
