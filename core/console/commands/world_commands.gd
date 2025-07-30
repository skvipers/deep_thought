extends RefCounted

const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

# === World Console Commands ===

class WorldRebuildCommand extends ConsoleCommand:
	func _init():
		super._init("world_rebuild", "Rebuild world chunks")
	
	func execute(args: Array) -> String:
		var world_preview = _find_world_preview()
		if not world_preview:
			return "❌ WorldPreview not found"
		
		world_preview.rebuild_chunks()
		return "🌍 World rebuilt"
	
	func get_usage() -> String:
		return "world_rebuild"
	
	func _find_world_preview():
		var scene_tree = Engine.get_main_loop().get_root()
		for node in scene_tree.get_children():
			if node.has_method("rebuild_chunks"):
				return node
		return null

class WorldInfoCommand extends ConsoleCommand:
	func _init():
		super._init("world_info", "Show world information")
	
	func execute(args: Array) -> String:
		var world_preview = _find_world_preview()
		if not world_preview:
			return "❌ WorldPreview not found"
		
		var chunk_count = world_preview.get_child_count()
		return "🌍 World info: " + str(chunk_count) + " chunks"
	
	func get_usage() -> String:
		return "world_info"
	
	func _find_world_preview():
		var scene_tree = Engine.get_main_loop().get_root()
		for node in scene_tree.get_children():
			if node.has_method("rebuild_chunks"):
				return node
		return null

class WorldGenerateCommand extends ConsoleCommand:
	func _init():
		super._init("world_generate", "Generate new world")
	
	func execute(args: Array) -> String:
		var world_preview = _find_world_preview()
		if not world_preview:
			return "❌ WorldPreview not found"
		
		world_preview.generate_world()
		return "🌍 World generated"
	
	func get_usage() -> String:
		return "world_generate"
	
	func _find_world_preview():
		var scene_tree = Engine.get_main_loop().get_root()
		for node in scene_tree.get_children():
			if node.has_method("generate_world"):
				return node
		return null 