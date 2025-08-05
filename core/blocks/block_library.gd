extends Resource
class_name BlockLibrary

const TAG := "BlockLibrary"

@export var blocks: Array[BlockType] = []
var blocks_by_id: Dictionary = {}
var blocks_by_name: Dictionary = {}
var _initialized: bool = false

func _init():
	resource_local_to_scene = true

func ensure_initialized():
	if _initialized:
		return

	if blocks.is_empty():
		Logger.error(TAG, "❌ Block list is empty! Please assign blocks in the inspector.")
		return

	Logger.debug(TAG, "🔧 Initializing block library with %d blocks..." % blocks.size())

	auto_assign_ids()
	build_lookup_tables()
	_initialized = true

func auto_assign_ids():
	for i in range(blocks.size()):
		if blocks[i]:
			blocks[i].id = i
			Logger.debug(TAG, "Assigned ID: %s → %d" % [blocks[i].name, i])

func build_lookup_tables():
	blocks_by_id.clear()
	blocks_by_name.clear()

	for i in range(blocks.size()):
		var block = blocks[i]

		if block == null:
			Logger.error(TAG, "❌ Block at index %d is null!" % i)
			continue

		if block.name.is_empty():
			Logger.error(TAG, "❌ Block at index %d has an empty name!" % i)
			continue

		blocks_by_id[block.id] = block
		blocks_by_name[block.name] = block

	Logger.debug(TAG, "Lookup tables built: %d by ID, %d by name." % [blocks_by_id.size(), blocks_by_name.size()])


func get_block_id(name: StringName) -> int:
	ensure_initialized()
	var block = blocks_by_name.get(name)
	if block:
		return block.id
	return -1  # Return -1, if block not found

func get_block_by_id(id: int) -> BlockType:
	ensure_initialized()
	return blocks_by_id.get(id, null)

func get_block_by_name(name: String) -> BlockType:
	ensure_initialized()
	return blocks_by_name.get(name, null)

func get_block_type(block_id: int) -> BlockType:
	ensure_initialized()
	return blocks_by_id.get(block_id, null)

func add_block(block: BlockType):
	if block:
		blocks.append(block)
		_initialized = false  # Reset to rebuild lookup tables
