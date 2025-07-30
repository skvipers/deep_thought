extends RefCounted
class_name GlobalJobQueue

## Central queue of all tasks waiting to be assigned
## Supports task reservation, cancellation, and filtering

const WorkTask = preload("res://addons/deep_thought/core/priority/work_task.gd")

## All pending tasks
var pending_tasks: Array[WorkTask] = []
## Tasks reserved by pawns (pawn -> task)
var reserved_tasks: Dictionary = {}
## Tasks currently being executed
var executing_tasks: Array[WorkTask] = []
## Tasks completed in this session
var completed_tasks: Array[WorkTask] = []

## Signals
signal task_added(task: WorkTask)
signal task_removed(task: WorkTask)
signal task_assigned(task: WorkTask, pawn)
signal task_completed(task: WorkTask, pawn)
signal task_failed(task: WorkTask, pawn)
signal task_cancelled(task: WorkTask)

func _init():
	pass

## Add a task to the global queue
func add_task(task: WorkTask):
	if task == null:
		return
	
	pending_tasks.append(task)
	task_added.emit(task)

## Remove a task from the global queue
func remove_task(task: WorkTask):
	if task == null:
		return
	
	# Remove from pending
	var pending_index = pending_tasks.find(task)
	if pending_index >= 0:
		pending_tasks.remove_at(pending_index)
		task_removed.emit(task)
	
	# Remove from reserved
	for pawn in reserved_tasks:
		if reserved_tasks[pawn] == task:
			reserved_tasks.erase(pawn)
			break
	
	# Remove from executing
	var executing_index = executing_tasks.find(task)
	if executing_index >= 0:
		executing_tasks.remove_at(executing_index)

## Get the best task for a pawn
func get_best_task_for_pawn(pawn) -> WorkTask:
	if pending_tasks.is_empty():
		return null
	
	# Check if pawn has a reserved task
	if reserved_tasks.has(pawn):
		var reserved = reserved_tasks[pawn]
		if reserved in pending_tasks:
			return reserved
	
	# Find the best task based on total priority
	var best_task: WorkTask = null
	var best_priority: int = -1
	
	for task in pending_tasks:
		# Skip if task is reserved by another pawn
		if is_task_reserved_by_other(task, pawn):
			continue
		
		# Check if pawn can execute this task
		if not task.can_be_executed_by(pawn):
			continue
		
		var total_priority = task.get_total_priority(pawn)
		if total_priority > best_priority:
			best_priority = total_priority
			best_task = task
	
	return best_task

## Reserve a task for a pawn
func reserve_task_for_pawn(task: WorkTask, pawn):
	if task == null or pawn == null:
		return false
	
	if task not in pending_tasks:
		return false
	
	if not task.can_be_executed_by(pawn):
		return false
	
	# Remove any existing reservation for this pawn
	if reserved_tasks.has(pawn):
		var old_reservation = reserved_tasks[pawn]
		if old_reservation in pending_tasks:
			# Return the old reservation to the queue
			pass
	
	reserved_tasks[pawn] = task
	return true

## Release a task reservation
func release_task_reservation(pawn):
	if reserved_tasks.has(pawn):
		reserved_tasks.erase(pawn)

## Assign a task to a pawn
func assign_task_to_pawn(task: WorkTask, pawn):
	if task == null or pawn == null:
		return false
	
	# Remove from pending
	var pending_index = pending_tasks.find(task)
	if pending_index >= 0:
		pending_tasks.remove_at(pending_index)
	
	# Remove from reserved
	if reserved_tasks.has(pawn) and reserved_tasks[pawn] == task:
		reserved_tasks.erase(pawn)
	
	# Add to executing
	executing_tasks.append(task)
	
	# Assign to pawn
	task.assign_to_pawn(pawn)
	
	task_assigned.emit(task, pawn)
	return true

## Mark task as completed
func complete_task(task: WorkTask, pawn):
	if task == null:
		return
	
	# Remove from executing
	var executing_index = executing_tasks.find(task)
	if executing_index >= 0:
		executing_tasks.remove_at(executing_index)
	
	# Add to completed
	completed_tasks.append(task)
	
	task_completed.emit(task, pawn)

## Mark task as failed
func fail_task(task: WorkTask, pawn):
	if task == null:
		return
	
	# Remove from executing
	var executing_index = executing_tasks.find(task)
	if executing_index >= 0:
		executing_tasks.remove_at(executing_index)
	
	task_failed.emit(task, pawn)

## Cancel a task
func cancel_task(task: WorkTask):
	if task == null:
		return
	
	# Remove from all queues
	remove_task(task)
	
	# Cancel the task
	task.cancel()
	
	task_cancelled.emit(task)

## Check if task is reserved by another pawn
func is_task_reserved_by_other(task: WorkTask, pawn) -> bool:
	for reserved_pawn in reserved_tasks:
		if reserved_pawn != pawn and reserved_tasks[reserved_pawn] == task:
			return true
	return false

## Get all pending tasks
func get_pending_tasks() -> Array[WorkTask]:
	return pending_tasks.duplicate()

## Get all executing tasks
func get_executing_tasks() -> Array[WorkTask]:
	return executing_tasks.duplicate()

## Get all completed tasks
func get_completed_tasks() -> Array[WorkTask]:
	return completed_tasks.duplicate()

## Get tasks by job type
func get_tasks_by_job_type(job_type: String) -> Array[WorkTask]:
	var result: Array[WorkTask] = []
	
	for task in pending_tasks:
		if task.job_type == job_type:
			result.append(task)
	
	return result

## Get tasks by state
func get_tasks_by_state(state: WorkTask.TaskState) -> Array[WorkTask]:
	var result: Array[WorkTask] = []
	
	var tasks_to_check: Array[WorkTask] = []
	match state:
		WorkTask.TaskState.PENDING:
			tasks_to_check = pending_tasks
		WorkTask.TaskState.IN_PROGRESS:
			tasks_to_check = executing_tasks
		WorkTask.TaskState.COMPLETED:
			tasks_to_check = completed_tasks
		_:
			return result
	
	for task in tasks_to_check:
		if task.state == state:
			result.append(task)
	
	return result

## Clear all tasks
func clear_all_tasks():
	for task in pending_tasks:
		task.cancel()
	
	pending_tasks.clear()
	reserved_tasks.clear()
	executing_tasks.clear()
	completed_tasks.clear()

## Get queue statistics
func get_queue_stats() -> Dictionary:
	return {
		"pending": pending_tasks.size(),
		"executing": executing_tasks.size(),
		"completed": completed_tasks.size(),
		"reserved": reserved_tasks.size()
	} 