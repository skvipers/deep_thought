extends Node3D
class_name SpawnManager

const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@export var pawn_scene: PackedScene
@export var world_generator: Node3D  # Reference to world generator

# Spawn settings
@export_group("Spawn Settings")
@export var auto_spawn_on_ready: bool = false
@export var spawn_count: int = 1
@export var spawn_delay: float = 0.1  # Delay between spawns
@export var max_spawned_pawns: int = 10  # Maximum number of spawned pawns
@export var spawn_height_offset: float = 2.0  # Height above surface

# Spawned pawns tracking
var spawned_pawns: Array[Node3D] = []
var spawn_timer: float = 0.0
var is_spawning: bool = false

func _ready():
	if auto_spawn_on_ready:
		# Add delay to ensure scene is fully initialized
		await get_tree().create_timer(0.5).timeout
		spawn_pawns()

func _process(delta):
	if is_spawning and spawn_timer > 0:
		spawn_timer -= delta
		if spawn_timer <= 0:
			# Use call_deferred to avoid blocking during process
			_spawn_single_pawn.call_deferred()

func spawn_pawns(count: int = -1):
	"""Spawn multiple pawns"""
	if count == -1:
		count = spawn_count
	
	if count <= 0:
		Logger.warn("PAWN", "❌ Invalid spawn count: " + str(count))
		return
	
	if spawned_pawns.size() >= max_spawned_pawns:
		Logger.warn("PAWN", "❌ Maximum spawned pawns reached: " + str(max_spawned_pawns))
		return
	
	Logger.info("PAWN", "🎮 Spawning " + str(count) + " pawns")
	
	is_spawning = true
	spawn_timer = spawn_delay
	
	# Spawn first pawn immediately
	_spawn_single_pawn()
	
	# Schedule remaining spawns
	for i in range(1, count):
		spawn_timer += spawn_delay

func _spawn_single_pawn():
	"""Spawn a single pawn"""
	if not pawn_scene:
		Logger.error("PAWN", "❌ Pawn scene not assigned to SpawnManager")
		return
	
	# Get spawn position
	var spawn_position = _get_spawn_position()
	
	# Create pawn
	var pawn = pawn_scene.instantiate()
	pawn.transform.origin = spawn_position
	
	# Use call_deferred to avoid blocking during setup
	get_tree().current_scene.add_child.call_deferred(pawn)
	
	# Track spawned pawn
	spawned_pawns.append(pawn)
	
	Logger.info("PAWN", "✅ Spawned pawn at: " + str(spawn_position))
	
	# Check if we're done spawning
	if spawned_pawns.size() >= spawn_count or spawned_pawns.size() >= max_spawned_pawns:
		is_spawning = false
		Logger.info("PAWN", "🎯 Finished spawning pawns. Total: " + str(spawned_pawns.size()))

func _get_spawn_position() -> Vector3:
	"""Get spawn position on surface"""
	var position = Vector3.ZERO
	
	# Try to get world center from world generator
	if world_generator and world_generator.has_method("get_world_center"):
		position = world_generator.get_world_center()
	elif world_generator and world_generator.has_method("get_world_bounds"):
		var bounds = world_generator.get_world_bounds()
		position = (bounds.position + bounds.end) / 2
	
	# Add some randomness
	position += Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
	
	# Find surface height at this position
	var surface_height = _find_surface_height(position)
	if surface_height != -1:
		position.y = surface_height + spawn_height_offset
		Logger.debug("PAWN", "Found surface at height: " + str(surface_height))
	else:
		# Fallback to default height
		position.y = spawn_height_offset
		Logger.warn("PAWN", "Could not find surface, using default height")
	
	return position

func _find_surface_height(position: Vector3) -> float:
	"""Find surface height at given position"""
	if not world_generator:
		return -1
	
	# Try to get surface height from OverlayManager
	if world_generator.has_method("get_overlay_manager"):
		var overlay_manager = world_generator.get_overlay_manager()
		if overlay_manager and overlay_manager.has_method("get_cached_surface_level"):
			var surface_height = overlay_manager.get_cached_surface_level(Vector3i(position))
			Logger.debug("PAWN", "Got surface height from OverlayManager: " + str(surface_height))
			return float(surface_height)
	
	# Try to get surface height from world generator directly
	if world_generator.has_method("get_surface_height"):
		var height = world_generator.get_surface_height(position.x, position.z)
		Logger.debug("PAWN", "Got surface height from world generator: " + str(height))
		return float(height)
	
	# Try to get from WorldPreview if available
	if world_generator.has_method("get_surface_position"):
		var surface_pos = world_generator.get_surface_position(Vector3i(position))
		if surface_pos != Vector3i.MAX:
			Logger.debug("PAWN", "Got surface position from world generator: " + str(surface_pos))
			return float(surface_pos.y)
	
	Logger.warn("PAWN", "Could not find surface height for position: " + str(position))
	return -1

func spawn_pawn_at_position(position: Vector3, rotation: Vector3 = Vector3.ZERO):
	"""Spawn pawn at specific position on surface"""
	if not pawn_scene:
		Logger.error("PAWN", "❌ Pawn scene not assigned to SpawnManager")
		return
	
	# Find surface height at this position
	var surface_height = _find_surface_height(position)
	if surface_height != -1:
		position.y = surface_height + spawn_height_offset
		Logger.debug("PAWN", "Found surface at height: " + str(surface_height))
	else:
		# Fallback to provided height
		position.y += spawn_height_offset
		Logger.warn("PAWN", "Could not find surface, using provided height")
	
	var transform = Transform3D()
	transform.origin = position
	transform.basis = Basis.from_euler(rotation)
	
	var pawn = pawn_scene.instantiate()
	pawn.transform = transform
	
	# Use call_deferred to avoid blocking during setup
	get_tree().current_scene.add_child.call_deferred(pawn)
	
	spawned_pawns.append(pawn)
	Logger.info("PAWN", "✅ Spawned pawn at specific position: " + str(position))

func clear_spawned_pawns():
	"""Clear all spawned pawns"""
	Logger.info("PAWN", "🗑️ Clearing " + str(spawned_pawns.size()) + " spawned pawns")
	
	for pawn in spawned_pawns:
		if is_instance_valid(pawn):
			pawn.queue_free()
	
	spawned_pawns.clear()

func get_spawned_pawns_count() -> int:
	"""Get count of spawned pawns"""
	return spawned_pawns.size()

func get_spawned_pawns() -> Array[Node3D]:
	"""Get array of spawned pawns"""
	return spawned_pawns

func get_spawn_info() -> Dictionary:
	"""Get spawn information"""
	return {
		"spawned_count": spawned_pawns.size(),
		"max_spawned": max_spawned_pawns,
		"auto_spawn": auto_spawn_on_ready,
		"spawn_count": spawn_count
	} 
