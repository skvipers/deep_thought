extends RefCounted

const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

# === Pawn Console Commands ===

class PawnSpawnCommand extends ConsoleCommand:
	func _init():
		super._init("pawn_spawn", "Spawn pawns")
	
	func execute(args: Array) -> String:
		var count = 1
		if args.size() > 0:
			count = int(args[0])
		
		# Find spawn manager
		var spawn_manager = _find_spawn_manager()
		if not spawn_manager:
			return "❌ SpawnManager not found"
		
		spawn_manager.spawn_pawns(count)
		return "✅ Spawned " + str(count) + " pawns"
	
	func get_usage() -> String:
		return "pawn_spawn [count]"
	
	func _find_spawn_manager():
		var scene_tree = Engine.get_main_loop().get_root()
		for node in scene_tree.get_children():
			if node.has_method("spawn_pawns"):
				return node
		return null

class PawnClearCommand extends ConsoleCommand:
	func _init():
		super._init("pawn_clear", "Clear all spawned pawns")
	
	func execute(args: Array) -> String:
		var spawn_manager = _find_spawn_manager()
		if not spawn_manager:
			return "❌ SpawnManager not found"
		
		spawn_manager.clear_spawned_pawns()
		return "🗑️ Cleared all pawns"
	
	func get_usage() -> String:
		return "pawn_clear"
	
	func _find_spawn_manager():
		var scene_tree = Engine.get_main_loop().get_root()
		for node in scene_tree.get_children():
			if node.has_method("clear_spawned_pawns"):
				return node
		return null

class PawnInfoCommand extends ConsoleCommand:
	func _init():
		super._init("pawn_info", "Show pawn information")
	
	func execute(args: Array) -> String:
		var spawn_manager = _find_spawn_manager()
		if not spawn_manager:
			return "❌ SpawnManager not found"
		
		var info = spawn_manager.get_spawn_info()
		return "📊 Pawns: " + str(info.spawned_count) + "/" + str(info.max_spawned)
	
	func get_usage() -> String:
		return "pawn_info"
	
	func _find_spawn_manager():
		var scene_tree = Engine.get_main_loop().get_root()
		for node in scene_tree.get_children():
			if node.has_method("get_spawn_info"):
				return node
		return null 