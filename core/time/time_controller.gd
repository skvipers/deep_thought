extends Node
class_name TimeController

const TickManager = preload("res://addons/deep_thought/core/time/tick_manager.gd")

## Global time scale (0.5 = slower, 2.0 = faster)
@export var time_scale: float = 1.0:
	set(value):
		time_scale = clamp(value, 0.0, 10.0)  # Limit to reasonable range
		_update_tick_manager()
	get:
		return time_scale

## Whether time is paused
@export var time_paused: bool = false:
	set(value):
		time_paused = value
		_update_tick_manager()
	get:
		return time_paused

## Reference to TickManager
@export var tick_manager: TickManager

## Time scale presets for UI
var time_scale_presets: Array[float] = [0.25, 0.5, 1.0, 2.0, 3.0, 5.0]

## Signals
signal time_scale_changed(new_scale: float)
signal time_paused_changed(paused: bool)

func _ready():
	# Find TickManager if not assigned
	if not tick_manager:
		tick_manager = _find_tick_manager()
	
	_update_tick_manager()

func _find_tick_manager() -> TickManager:
	# Try to find TickManager in the scene tree
	var root = get_tree().root
	return _find_tick_manager_recursive(root)

func _find_tick_manager_recursive(node: Node) -> TickManager:
	if node is TickManager:
		return node
	for child in node.get_children():
		var found = _find_tick_manager_recursive(child)
		if found:
			return found
	return null

func _update_tick_manager():
	if tick_manager:
		tick_manager.time_scale = time_scale if not time_paused else 0.0
	
	emit_signal("time_scale_changed", time_scale)
	emit_signal("time_paused_changed", time_paused)

## Set time scale with validation
func set_time_scale(scale: float):
	time_scale = clamp(scale, 0.0, 10.0)

## Pause/unpause time
func set_paused(paused: bool):
	time_paused = paused

## Toggle pause state
func toggle_pause():
	time_paused = not time_paused

## Set time scale to a preset value
func set_time_scale_preset(index: int):
	if index >= 0 and index < time_scale_presets.size():
		time_scale = time_scale_presets[index]

## Get current time scale as a string for UI
func get_time_scale_string() -> String:
	if time_paused:
		return "PAUSED"
	return "x" + str(time_scale)

## Get time scale percentage for UI
func get_time_scale_percentage() -> float:
	return time_scale * 100.0

## Set time scale from percentage
func set_time_scale_percentage(percentage: float):
	time_scale = percentage / 100.0

## Get available presets for UI
func get_presets() -> Array[Dictionary]:
	var presets = []
	for i in range(time_scale_presets.size()):
		presets.append({
			"index": i,
			"scale": time_scale_presets[i],
			"label": "x" + str(time_scale_presets[i])
		})
	return presets

## Get current preset index
func get_current_preset_index() -> int:
	for i in range(time_scale_presets.size()):
		if abs(time_scale_presets[i] - time_scale) < 0.01:
			return i
	return -1

## Slow down time (multiply by factor)
func slow_down(factor: float = 0.5):
	time_scale *= factor

## Speed up time (multiply by factor)
func speed_up(factor: float = 2.0):
	time_scale *= factor

## Reset to normal speed
func reset_speed():
	time_scale = 1.0
	time_paused = false 