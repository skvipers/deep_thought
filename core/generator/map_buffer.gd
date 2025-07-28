extends Resource
class_name MapBuffer

var blocks: Dictionary = {}
var overlays: Dictionary = {}

func set_block(pos: Vector3i, block_id: int) -> void:
	blocks[pos] = block_id

func get_block(pos: Vector3i) -> int:
	return blocks.get(pos, -1)

func has_block(pos: Vector3i) -> bool:
	return blocks.has(pos)

func clear() -> void:
	blocks.clear()

func get_all_blocks() -> Dictionary:
	return blocks

func get_block_positions() -> Array:
	return blocks.keys()

func set_overlay_block(pos: Vector3i, overlay_type: int, base_block_id: int = -1) -> void:
	overlays[pos] = {
		"type": overlay_type,
		"base_block_id": base_block_id
	}


func get_overlay_block(pos: Vector3i) -> Dictionary:
	return overlays.get(pos, null)
