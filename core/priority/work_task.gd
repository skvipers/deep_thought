extends RefCounted
class_name WorkTask

const PrioritySystem = preload("res://addons/deep_thought/core/priority/priority_system.gd")

## Job type for this work task (string ID)
var job_type: String = ""
## Base priority of the task
var base_priority: int = PrioritySystem.priority_scale_default
## Temporary boost priority
var boost_priority: int = 0
## Target object for this task
var target_object
## Assigned pawn (null if unassigned)
var assigned_pawn
## Task state
enum TaskState {
	PENDING,    # Waiting to be assigned
	ASSIGNED,   # Assigned to a pawn
	IN_PROGRESS, # Currently being worked on
	COMPLETED,  # Finished successfully
	FAILED,     # Failed to complete
	CANCELLED   # Cancelled by player or system
}
var state: TaskState = TaskState.PENDING
## Task creation time
var creation_time: float = 0.0
## Task start time
var start_time: float = 0.0
## Task completion time
var completion_time: float = 0.0
## Task description
var description: String = ""
## Task requirements
var requirements: Dictionary = {}
## Task progress (0.0 to 1.0)
var progress: float = 0.0
## Manual flag - true if assigned by player
var is_manual: bool = false
## Immediate flag - true if task executes without pawn involvement
var is_immediate: bool = false

func _init(task_job_type: String, task_base_priority: int = PrioritySystem.priority_scale_default):
	job_type = task_job_type
	base_priority = task_base_priority
	creation_time = Time.get_ticks_msec()

## Get total priority for a specific pawn
func get_total_priority(pawn) -> int:
	var pawn_priority = get_pawn_priority(pawn)
	return PrioritySystem.calculate_priority(pawn_priority, base_priority, boost_priority)

## Get pawn's priority for this job type
func get_pawn_priority(pawn) -> int:
	if pawn.has_method("get_job_priority"):
		return pawn.get_job_priority(job_type)
	return PrioritySystem.priority_scale_default

## Add priority boost
func add_priority_boost(boost: int):
	boost_priority += boost

## Remove priority boost
func remove_priority_boost(boost: int):
	boost_priority = max(0, boost_priority - boost)

## Clear all priority boosts
func clear_priority_boosts():
	boost_priority = 0

## Assign task to a pawn
func assign_to_pawn(pawn):
	assigned_pawn = pawn
	state = TaskState.ASSIGNED

## Start working on task
func start_work():
	if state == TaskState.ASSIGNED:
		state = TaskState.IN_PROGRESS
		start_time = Time.get_ticks_msec()

## Start executing task (alias for start_work for compatibility)
func start_execution():
	start_work()

## Complete task
func complete():
	state = TaskState.COMPLETED
	completion_time = Time.get_ticks_msec()
	progress = 1.0

## Fail task
func fail():
	state = TaskState.FAILED
	completion_time = Time.get_ticks_msec()

## Cancel task
func cancel():
	state = TaskState.CANCELLED
	completion_time = Time.get_ticks_msec()

## Update progress
func update_progress(new_progress: float):
	progress = clamp(new_progress, 0.0, 1.0)
	if progress >= 1.0:
		complete()

## Check if task can be worked on by pawn
func can_be_worked_by(pawn) -> bool:
	# Check basic requirements
	if not requirements.is_empty():
		for requirement in requirements:
			if not check_requirement(pawn, requirement, requirements[requirement]):
				return false
	
	# Check if pawn has required skills
	return has_required_skills(pawn)

## Check if task can be executed by pawn (alias for can_be_worked_by for compatibility)
func can_be_executed_by(pawn) -> bool:
	return can_be_worked_by(pawn)

## Check specific requirement
func check_requirement(pawn, requirement: String, value) -> bool:
	match requirement:
		"skill_level":
			var skill_name = value.skill
			var min_level = value.level
			return pawn.get_skill_level(skill_name) >= min_level
		"health":
			return pawn.health >= value
		"energy":
			return pawn.energy >= value
		"distance":
			var max_distance = value
			return pawn.global_position.distance_to(target_object.global_position) <= max_distance
		_:
			return true

## Check if pawn has required skills (override in subclasses)
func has_required_skills(pawn) -> bool:
	return true

## Get task duration
func get_duration() -> float:
	if start_time == 0.0:
		return 0.0
	if completion_time == 0.0:
		return (Time.get_ticks_msec() - start_time) / 1000.0
	return (completion_time - start_time) / 1000.0

## Get task age
func get_age() -> float:
	return (Time.get_ticks_msec() - creation_time) / 1000.0

## Get display name for UI
func get_display_name() -> String:
	var job_info = PrioritySystem.get_job_type_info(job_type)
	var job_name = job_info.get("display_name", job_type)
	return "Task: " + job_name

## Get description for UI
func get_description() -> String:
	return description

## Get priority string for UI
func get_priority_string() -> String:
	return "Priority: " + str(get_total_priority(null)) + " (Base: " + str(base_priority) + ", Boost: " + str(boost_priority) + ")"

## Execute task (standard - requires pawn)
func execute(pawn):
	if not can_be_executed_by(pawn):
		fail()
		return
	
	start_execution()
	# Override in subclasses to implement specific behavior
	complete()

## Execute task directly (immediate - no pawn required)
func execute_direct():
	if not is_immediate:
		fail()
		return
	
	start_execution()
	# Override in subclasses to implement specific behavior
	complete()

## Get state string for UI
func get_state_string() -> String:
	match state:
		TaskState.PENDING:
			return "Pending"
		TaskState.ASSIGNED:
			return "Assigned"
		TaskState.IN_PROGRESS:
			return "In Progress (" + str(int(progress * 100)) + "%)"
		TaskState.COMPLETED:
			return "Completed"
		TaskState.FAILED:
			return "Failed"
		TaskState.CANCELLED:
			return "Cancelled"
		_:
			return "Unknown"
