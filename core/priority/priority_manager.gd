extends Node
class_name PriorityManager

const PrioritySystem = preload("res://addons/deep_thought/core/priority/priority_system.gd")
const WorkTask = preload("res://addons/deep_thought/core/priority/work_task.gd")
const Prioritizable = preload("res://addons/deep_thought/core/priority/prioritizable.gd")

## Available pawns for work assignment
var available_pawns: Array = []
## Pending tasks waiting for assignment
var pending_tasks: Array[WorkTask] = []
## Active tasks being worked on
var active_tasks: Array[WorkTask] = []
## Completed tasks (for history)
var completed_tasks: Array[WorkTask] = []
## Priority calculation mode
var priority_mode: PrioritySystem.PriorityMode = PrioritySystem.PriorityMode.ADDITIVE
## Whether to allow task interruption
var allow_interruption: bool = true
## Maximum tasks per pawn
var max_tasks_per_pawn: int = 3
## Task assignment interval (seconds)
var assignment_interval: float = 1.0
var last_assignment_time: float = 0.0

## Signals
signal task_added(task: WorkTask)
signal task_assigned(task: WorkTask, pawn)
signal task_completed(task: WorkTask, pawn)
signal task_failed(task: WorkTask, pawn)
signal task_cancelled(task: WorkTask)
signal priority_recalculated()

func _ready():
	# Start assignment timer
	var timer = Timer.new()
	timer.wait_time = assignment_interval
	timer.timeout.connect(_process_task_assignments)
	add_child(timer)
	timer.start()

func _process(delta):
	# Process active tasks
	_process_active_tasks(delta)

## Add a new task to the queue
func add_task(task: WorkTask):
	pending_tasks.append(task)
	emit_signal("task_added", task)

## Remove a task from the queue
func remove_task(task: WorkTask):
	if task in pending_tasks:
		pending_tasks.erase(task)
	elif task in active_tasks:
		active_tasks.erase(task)
		task.cancel()
		emit_signal("task_cancelled", task)

## Add a pawn to the available workforce
func add_pawn(pawn):
	if pawn not in available_pawns:
		available_pawns.append(pawn)

## Remove a pawn from the available workforce
func remove_pawn(pawn):
	if pawn in available_pawns:
		available_pawns.erase(pawn)
	
	# Cancel all tasks assigned to this pawn
	for task in active_tasks:
		if task.assigned_pawn == pawn:
			task.cancel()
			emit_signal("task_cancelled", task)

## Process task assignments
func _process_task_assignments():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_assignment_time < assignment_interval:
		return
	
	last_assignment_time = current_time
	
	# Sort pending tasks by priority
	pending_tasks.sort_custom(_sort_tasks_by_priority)
	
	# Try to assign tasks to available pawns
	for task in pending_tasks:
		var best_pawn = _find_best_pawn_for_task(task)
		if best_pawn:
			_assign_task_to_pawn(task, best_pawn)

## Sort tasks by priority (highest first)
func _sort_tasks_by_priority(a: WorkTask, b: WorkTask) -> bool:
	# Get highest priority for each task across all pawns
	var a_priority = _get_highest_priority_for_task(a)
	var b_priority = _get_highest_priority_for_task(b)
	return a_priority > b_priority

## Get highest priority for a task across all pawns
func _get_highest_priority_for_task(task: WorkTask) -> int:
	var highest_priority = 0
	for pawn in available_pawns:
		var priority = task.get_total_priority(pawn)
		highest_priority = max(highest_priority, priority)
	return highest_priority

## Find the best pawn for a task
func _find_best_pawn_for_task(task: WorkTask):
	var best_pawn = null
	var best_priority = -1
	
	for pawn in available_pawns:
		# Check if pawn can work on this task
		if not task.can_be_worked_by(pawn):
			continue
		
		# Check if pawn has capacity for more tasks
		if _get_pawn_task_count(pawn) >= max_tasks_per_pawn:
			continue
		
		# Calculate priority for this pawn
		var priority = task.get_total_priority(pawn)
		if priority > best_priority:
			best_priority = priority
			best_pawn = pawn
	
	return best_pawn

## Get number of tasks assigned to a pawn
func _get_pawn_task_count(pawn) -> int:
	var count = 0
	for task in active_tasks:
		if task.assigned_pawn == pawn:
			count += 1
	return count

## Assign task to pawn
func _assign_task_to_pawn(task: WorkTask, pawn):
	task.assign_to_pawn(pawn)
	pending_tasks.erase(task)
	active_tasks.append(task)
	emit_signal("task_assigned", task, pawn)

## Process active tasks
func _process_active_tasks(delta):
	for task in active_tasks:
		if task.state == WorkTask.TaskState.IN_PROGRESS:
			_process_task_work(task, delta)
		elif task.state == WorkTask.TaskState.COMPLETED:
			_complete_task(task)
		elif task.state == WorkTask.TaskState.FAILED:
			_fail_task(task)

## Process work on a task
func _process_task_work(task: WorkTask, delta):
	# This is where you'd implement the actual work logic
	# For now, just simulate progress
	if task.progress < 1.0:
		task.update_progress(task.progress + delta * 0.1)  # 10% per second

## Complete a task
func _complete_task(task: WorkTask):
	active_tasks.erase(task)
	completed_tasks.append(task)
	emit_signal("task_completed", task, task.assigned_pawn)

## Fail a task
func _fail_task(task: WorkTask):
	active_tasks.erase(task)
	completed_tasks.append(task)
	emit_signal("task_failed", task, task.assigned_pawn)

## Get all tasks for a pawn
func get_pawn_tasks(pawn) -> Array[WorkTask]:
	var tasks = []
	for task in active_tasks:
		if task.assigned_pawn == pawn:
			tasks.append(task)
	return tasks

## Get all pending tasks
func get_pending_tasks() -> Array[WorkTask]:
	return pending_tasks

## Get all active tasks
func get_active_tasks() -> Array[WorkTask]:
	return active_tasks

## Get all completed tasks
func get_completed_tasks() -> Array[WorkTask]:
	return completed_tasks

## Get task statistics
func get_task_stats() -> Dictionary:
	return {
		"pending": pending_tasks.size(),
		"active": active_tasks.size(),
		"completed": completed_tasks.size(),
		"total_pawns": available_pawns.size(),
		"available_pawns": available_pawns.size()
	}

## Force reassignment of all tasks
func force_reassignment():
	# Move all active tasks back to pending
	for task in active_tasks:
		task.cancel()
		pending_tasks.append(task)
	
	active_tasks.clear()
	emit_signal("priority_recalculated")

## Clear all tasks
func clear_all_tasks():
	for task in pending_tasks:
		task.cancel()
	for task in active_tasks:
		task.cancel()
	
	pending_tasks.clear()
	active_tasks.clear()
	completed_tasks.clear()

## Add priority boost to all tasks of a specific type
func add_priority_boost_to_job_type(job_type: String, boost: int):
	for task in pending_tasks:
		if task.job_type == job_type:
			task.add_priority_boost(boost)
	
	for task in active_tasks:
		if task.job_type == job_type:
			task.add_priority_boost(boost)
	
	emit_signal("priority_recalculated") 