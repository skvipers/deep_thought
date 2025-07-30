extends RefCounted
class_name Prioritizable

const PrioritySystem = preload("res://addons/deep_thought/core/priority/priority_system.gd")

## Base priority for this object
var base_priority: int = PrioritySystem.priority_scale_default
## Temporary boost priority (for urgency)
var boost_priority: int = 0
## Job type for this prioritizable object (string ID)
var job_type: String = ""
## Whether this object is currently available for work
var is_available: bool = true
## Whether this object can be interrupted
var can_interrupt: bool = true
## Custom priority modifiers
var priority_modifiers: Dictionary = {}

## Get the total priority for a specific pawn
func get_total_priority(pawn) -> int:
	var pawn_priority = get_pawn_priority(pawn)
	return PrioritySystem.calculate_priority(pawn_priority, base_priority, boost_priority)

## Get pawn's priority for this job type (override in subclasses)
func get_pawn_priority(pawn) -> int:
	if pawn.has_method("get_job_priority"):
		return pawn.get_job_priority(job_type)
	return PrioritySystem.priority_scale_default

## Add a temporary priority boost
func add_priority_boost(boost: int):
	boost_priority += boost

## Remove priority boost
func remove_priority_boost(boost: int):
	boost_priority = max(0, boost_priority - boost)

## Clear all priority boosts
func clear_priority_boosts():
	boost_priority = 0

## Set custom priority modifier for specific conditions
func set_priority_modifier(condition: String, modifier: int):
	priority_modifiers[condition] = modifier

## Get priority modifier for specific condition
func get_priority_modifier(condition: String) -> int:
	return priority_modifiers.get(condition, 0)

## Check if this object can be worked on by the given pawn
func can_be_worked_by(pawn) -> bool:
	return is_available and has_required_skills(pawn)

## Check if pawn has required skills (override in subclasses)
func has_required_skills(pawn) -> bool:
	return true

## Called when work starts on this object
func on_work_started(pawn):
	pass

## Called when work is completed on this object
func on_work_completed(pawn):
	pass

## Called when work is interrupted on this object
func on_work_interrupted(pawn):
	pass

## Get display name for UI
func get_display_name() -> String:
	return "Prioritizable Object"

## Get description for UI
func get_description() -> String:
	return "A prioritizable work object"

## Get current priority as string for UI
func get_priority_string() -> String:
	var total = get_total_priority(null)  # null for base calculation
	return "Priority: " + str(total) + " (Base: " + str(base_priority) + ", Boost: " + str(boost_priority) + ")" 