extends Node
class_name ExampleTickable

const Tickable = preload("res://addons/deep_thought/core/time/tickable.gd")
const TickSystem = preload("res://addons/deep_thought/core/time/tick_system.gd")

## Example tickable that extends the base Tickable
var tickable: Tickable

## Custom properties for this example
var tick_count: int = 0
var last_tick_time: float = 0.0

func _ready():
	# Create a tickable instance
	tickable = Tickable.new()
	tickable.tick_level = TickSystem.TickLevel.MEDIUM
	tickable.tick_weight = 1.0
	
	# Register with TickManager (assuming it's in the scene)
	var tick_manager = _find_tick_manager()
	if tick_manager:
		tick_manager.register_tickable(tickable, TickSystem.TickLevel.MEDIUM)

func _on_tick(delta: float):
	tick_count += 1
	last_tick_time = Time.get_time_dict_from_system()["unix"]
	
	# Example tick logic
	print("ExampleTickable ticked! Count: ", tick_count, " Delta: ", delta)
	
	# You can implement any simulation logic here
	# For example: AI updates, physics calculations, etc.

func _find_tick_manager():
	var root = get_tree().root
	return _find_tick_manager_recursive(root)

func _find_tick_manager_recursive(node: Node):
	if node.has_method("register_tickable"):
		return node
	for child in node.get_children():
		var found = _find_tick_manager_recursive(child)
		if found:
			return found
	return null

func _exit_tree():
	# Unregister when destroyed
	if tickable:
		var tick_manager = _find_tick_manager()
		if tick_manager:
			tick_manager.unregister_tickable(tickable) 
