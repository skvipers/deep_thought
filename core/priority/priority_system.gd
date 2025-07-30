extends RefCounted
class_name PrioritySystem

## Priority calculation modes
enum PriorityMode {
	ADDITIVE,      # pawn_priority * base_priority + boost_priority
	MULTIPLICATIVE, # (pawn_priority + base_priority) * boost_priority
	WEIGHTED       # pawn_priority * base_priority * boost_priority
}

## Global job type registry - games can register their own job types
static var registered_job_types: Dictionary = {}
## Global priority scale settings - configurable by developer
static var priority_scale_min: int = 1
static var priority_scale_max: int = 5
static var priority_scale_default: int = 3

## Register a new job type
static func register_job_type(job_id: String, display_name: String, default_priority: int = priority_scale_default, description: String = "") -> void:
	registered_job_types[job_id] = {
		"id": job_id,
		"display_name": display_name,
		"default_priority": default_priority,
		"description": description
	}

## Unregister a job type
static func unregister_job_type(job_id: String) -> void:
	registered_job_types.erase(job_id)

## Get all registered job types
static func get_registered_job_types() -> Dictionary:
	return registered_job_types

## Check if job type is registered
static func is_job_type_registered(job_id: String) -> bool:
	return job_id in registered_job_types

## Get job type info
static func get_job_type_info(job_id: String) -> Dictionary:
	return registered_job_types.get(job_id, {})

## Set priority scale range
static func set_priority_scale(min_priority: int, max_priority: int, default_priority: int = -1) -> void:
	priority_scale_min = min_priority
	priority_scale_max = max_priority
	if default_priority == -1:
		priority_scale_default = (min_priority + max_priority) / 2
	else:
		priority_scale_default = clamp(default_priority, min_priority, max_priority)

## Get priority scale info
static func get_priority_scale_info() -> Dictionary:
	return {
		"min": priority_scale_min,
		"max": priority_scale_max,
		"default": priority_scale_default
	}

## Validate priority value
static func validate_priority(priority: int) -> int:
	return clamp(priority, priority_scale_min, priority_scale_max)

## Priority calculation helper
static func calculate_priority(pawn_priority: int, base_priority: int, boost_priority: int, mode: PriorityMode = PriorityMode.ADDITIVE) -> int:
	match mode:
		PriorityMode.ADDITIVE:
			return pawn_priority * base_priority + boost_priority
		PriorityMode.MULTIPLICATIVE:
			return (pawn_priority + base_priority) * boost_priority
		PriorityMode.WEIGHTED:
			return pawn_priority * base_priority * boost_priority
		_:
			return pawn_priority * base_priority + boost_priority

 