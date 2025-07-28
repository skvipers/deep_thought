extends Resource
class_name OverlayChunkData

@export var overlay_states: Dictionary = {}  # Vector3i -> BlockOverlayState

func save_to_file(file_path: String):
	ResourceSaver.save(self, file_path)

static func load_from_file(file_path: String) -> OverlayChunkData:
	if ResourceLoader.exists(file_path):
		return ResourceLoader.load(file_path) as OverlayChunkData
	return null
