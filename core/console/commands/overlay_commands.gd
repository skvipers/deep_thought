extends RefCounted

const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

# === Overlay Console Commands ===

class GrassGenerateCommand extends ConsoleCommand:
	func _init():
		super._init("grass_generate", "Generate grass overlays")
	
	func execute(args: Array) -> String:
		var grass_overlay = _find_grass_overlay()
		if not grass_overlay:
			return "❌ GrassOverlay not found"
		
		var radius = 8
		if args.size() > 0:
			radius = int(args[0])
		
		grass_overlay.generate_grass_on_surface()
		return "🌱 Generated grass with radius " + str(radius)
	
	func get_usage() -> String:
		return "grass_generate [radius]"
	
	func _find_grass_overlay():
		var scene_tree = Engine.get_main_loop().get_root()
		for node in scene_tree.get_children():
			if node.has_method("generate_grass_on_surface"):
				return node
		return null

class OverlayClearCommand extends ConsoleCommand:
	func _init():
		super._init("overlay_clear", "Clear all overlays")
	
	func execute(args: Array) -> String:
		var grass_overlay = _find_grass_overlay()
		if not grass_overlay:
			return "❌ GrassOverlay not found"
		
		var radius = 8
		if args.size() > 0:
			radius = int(args[0])
		
		grass_overlay.clear_overlays_in_area(Vector3i.ZERO, radius)
		return "🧹 Cleared overlays in radius " + str(radius)
	
	func get_usage() -> String:
		return "overlay_clear [radius]"
	
	func _find_grass_overlay():
		var scene_tree = Engine.get_main_loop().get_root()
		for node in scene_tree.get_children():
			if node.has_method("clear_overlays_in_area"):
				return node
		return null

class OverlayInfoCommand extends ConsoleCommand:
	func _init():
		super._init("overlay_info", "Show overlay information")
	
	func execute(args: Array) -> String:
		var grass_overlay = _find_grass_overlay()
		if not grass_overlay:
			return "❌ GrassOverlay not found"
		
		var stats = grass_overlay.get_overlay_statistics()
		return "📊 Overlay statistics: " + str(stats)
	
	func get_usage() -> String:
		return "overlay_info"
	
	func _find_grass_overlay():
		var scene_tree = Engine.get_main_loop().get_root()
		for node in scene_tree.get_children():
			if node.has_method("get_overlay_statistics"):
				return node
		return null 