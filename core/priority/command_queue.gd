extends RefCounted
class_name CommandQueue

## Per-pawn task queue
## Contains ordered list of tasks for a specific pawn

const WorkTask = preload("res://addons/deep_thought/core/priority/work_task.gd")

## The pawn this queue belongs to
var pawn = null
## Ordered list of tasks in the queue
var task_queue: Array[WorkTask] = []
## Current task being executed
var current_task: WorkTask = null
## Queue mode
enum QueueMode {
	AUTO,      # Automatic assignment from global queue
	MANUAL,    # Manual assignment by player
	MIXED      # Both auto and manual tasks
}
var queue_mode: QueueMode = QueueMode.AUTO
## Priority threshold for preemption
var preemption_threshold: int = 2

## Signals
signal task_added(task: WorkTask)
signal task_removed(task: WorkTask)
signal task_started(task: WorkTask)
signal task_completed(task: WorkTask)
signal task_failed(task: WorkTask)
signal queue_cleared()

func _init(pawn_owner):
	pawn = pawn_owner

## Add a task to the queue
func add_task(task: WorkTask):
	if task == null:
		return
	
	task_queue.append(task)
	task_added.emit(task)

## Add a task to the front of the queue (high priority)
func add_task_front(task: WorkTask):
	if task == null:
		return
	
	task_queue.insert(0, task)
	task_added.emit(task)

## Remove a task from the queue
func remove_task(task: WorkTask):
	if task == null:
		return
	
	var index = task_queue.find(task)
	if index >= 0:
		task_queue.remove_at(index)
		task_removed.emit(task)

## Get the next task from the queue
func get_next_task() -> WorkTask:
	if task_queue.is_empty():
		return null
	
	return task_queue[0]

## Start executing the next task
func start_next_task():
	if task_queue.is_empty():
		return null
	
	var next_task = task_queue[0]
	task_queue.remove_at(0)
	
	current_task = next_task
	task_started.emit(next_task)
	
	return next_task

## Complete the current task
func complete_current_task():
	if current_task == null:
		return
	
	task_completed.emit(current_task)
	current_task = null

## Fail the current task
func fail_current_task():
	if current_task == null:
		return
	
	task_failed.emit(current_task)
	current_task = null

## Clear the entire queue
func clear_queue():
	for task in task_queue:
		task.cancel()
	
	task_queue.clear()
	
	if current_task != null:
		current_task.cancel()
		current_task = null
	
	queue_cleared.emit()

## Check if queue is empty
func is_empty() -> bool:
	return task_queue.is_empty()

## Get queue size
func get_queue_size() -> int:
	return task_queue.size()

## Get all tasks in the queue
func get_all_tasks() -> Array[WorkTask]:
	return task_queue.duplicate()

## Check if a task can preempt the current task
func can_preempt_with(task: WorkTask) -> bool:
	if current_task == null:
		return true
	
	if task == null:
		return false
	
	# Check if the new task has significantly higher priority
	var current_priority = current_task.get_total_priority(pawn)
	var new_priority = task.get_total_priority(pawn)
	
	return new_priority >= current_priority + preemption_threshold

## Preempt current task with a new one
func preempt_with(task: WorkTask):
	if not can_preempt_with(task):
		return false
	
	# Cancel current task
	if current_task != null:
		current_task.cancel()
		current_task = null
	
	# Add new task to front
	add_task_front(task)
	
	return true

## Set queue mode
func set_queue_mode(mode: QueueMode):
	queue_mode = mode

## Get queue mode
func get_queue_mode() -> QueueMode:
	return queue_mode

## Check if queue accepts automatic tasks
func accepts_auto_tasks() -> bool:
	return queue_mode == QueueMode.AUTO or queue_mode == QueueMode.MIXED

## Check if queue accepts manual tasks
func accepts_manual_tasks() -> bool:
	return queue_mode == QueueMode.MANUAL or queue_mode == QueueMode.MIXED

## Get queue statistics
func get_queue_stats() -> Dictionary:
	return {
		"queue_size": task_queue.size(),
		"current_task": current_task != null,
		"queue_mode": queue_mode,
		"preemption_threshold": preemption_threshold
	} 