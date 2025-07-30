extends Node
class_name PriorityComponent

const PrioritySystem = preload("res://addons/deep_thought/core/priority/priority_system.gd")
const Prioritizable = preload("res://addons/deep_thought/core/priority/prioritizable.gd")

## The prioritizable object this component manages
var prioritizable: Prioritizable
## Job type for this component (string ID)
@export var job_type: String = ""
## Base priority level
@export var base_priority: int = PrioritySystem.priority_scale_default:
	set(value):
		base_priority = value
		if prioritizable:
			prioritizable.base_priority = value
	get:
		return base_priority

## Whether this component is enabled
@export var enabled: bool = true
## Whether this component can be modified by players
@export var player_modifiable: bool = true
## Custom priority modifiers
@export var custom_modifiers: Dictionary = {}

## Signals
signal priority_changed(new_priority: int)
signal boost_added(boost: int)
signal boost_removed(boost: int)
signal work_started(pawn)
signal work_completed(pawn)
signal work_interrupted(pawn)

func _ready():
	# Create prioritizable if not assigned
	if not prioritizable:
		prioritizable = Prioritizable.new()
		prioritizable.job_type = job_type
		prioritizable.base_priority = base_priority
	
	# Connect signals
	prioritizable.connect("work_started", _on_work_started)
	prioritizable.connect("work_completed", _on_work_completed)
	prioritizable.connect("work_interrupted", _on_work_interrupted)

## Get total priority for a specific pawn
func get_total_priority(pawn) -> int:
	if not enabled:
		return 0
	return prioritizable.get_total_priority(pawn)

## Add priority boost
func add_priority_boost(boost: int):
	if not enabled:
		return
	
	prioritizable.add_priority_boost(boost)
	emit_signal("boost_added", boost)

## Remove priority boost
func remove_priority_boost(boost: int):
	if not enabled:
		return
	
	prioritizable.remove_priority_boost(boost)
	emit_signal("boost_removed", boost)

## Clear all priority boosts
func clear_priority_boosts():
	if not enabled:
		return
	
	prioritizable.clear_priority_boosts()

## Set base priority
func set_base_priority(priority: int):
	if not enabled or not player_modifiable:
		return
	
	base_priority = priority
	prioritizable.base_priority = priority
	emit_signal("priority_changed", priority)

## Get priority as string for UI
func get_priority_string() -> String:
	if not enabled:
		return "Disabled"
	return prioritizable.get_priority_string()

## Check if pawn can work on this
func can_be_worked_by(pawn) -> bool:
	if not enabled:
		return false
	return prioritizable.can_be_worked_by(pawn)

## Set custom modifier
func set_custom_modifier(condition: String, modifier: int):
	custom_modifiers[condition] = modifier
	prioritizable.set_priority_modifier(condition, modifier)

## Get custom modifier
func get_custom_modifier(condition: String) -> int:
	return custom_modifiers.get(condition, 0)

## Enable/disable this component
func set_enabled(enabled_state: bool):
	enabled = enabled_state
	if not enabled:
		clear_priority_boosts()

## Signal handlers
func _on_work_started(pawn):
	emit_signal("work_started", pawn)

func _on_work_completed(pawn):
	emit_signal("work_completed", pawn)

func _on_work_interrupted(pawn):
	emit_signal("work_interrupted", pawn)

## Get display information for UI
func get_display_info() -> Dictionary:
	var job_info = PrioritySystem.get_job_type_info(job_type)
	var job_display_name = job_info.get("display_name", job_type)
	
	return {
		"job_type": job_display_name,
		"base_priority": base_priority,
		"boost_priority": prioritizable.boost_priority,
		"total_priority": get_total_priority(null),
		"enabled": enabled,
		"modifiable": player_modifiable,
		"available": prioritizable.is_available
	} 