extends RefCounted
class_name CommandDispatcher

## Connects GlobalJobQueue and pawns
## Distributes tasks dynamically or by player override

const GlobalJobQueue = preload("res://addons/deep_thought/core/priority/global_job_queue.gd")
const CommandQueue = preload("res://addons/deep_thought/core/priority/command_queue.gd")
const WorkTask = preload("res://addons/deep_thought/core/priority/work_task.gd")

## Global job queue
var global_queue: GlobalJobQueue
## Pawn task queues (pawn -> CommandQueue)
var pawn_queues: Dictionary = {}
## Assignment mode
enum AssignmentMode {
	AUTOMATIC,  # Automatic assignment based on priorities
	MANUAL,     # Manual assignment by player
	HYBRID      # Both automatic and manual
}
var assignment_mode: AssignmentMode = AssignmentMode.AUTOMATIC
## Assignment interval (seconds)
var assignment_interval: float = 1.0
## Last assignment time
var last_assignment_time: float = 0.0

## Signals
signal pawn_added(pawn)
signal pawn_removed(pawn)
signal task_assigned(task: WorkTask, pawn)
signal task_completed(task: WorkTask, pawn)
signal task_failed(task: WorkTask, pawn)

func _init():
	global_queue = GlobalJobQueue.new()
	
	# Connect global queue signals
	global_queue.task_assigned.connect(_on_global_task_assigned)
	global_queue.task_completed.connect(_on_global_task_completed)
	global_queue.task_failed.connect(_on_global_task_failed)

## Add a pawn to the dispatcher
func add_pawn(pawn):
	if pawn == null:
		return
	
	if pawn_queues.has(pawn):
		return
	
	var command_queue = CommandQueue.new(pawn)
	pawn_queues[pawn] = command_queue
	
	# Connect pawn queue signals
	command_queue.task_started.connect(_on_pawn_task_started)
	command_queue.task_completed.connect(_on_pawn_task_completed)
	command_queue.task_failed.connect(_on_pawn_task_failed)
	
	pawn_added.emit(pawn)

## Remove a pawn from the dispatcher
func remove_pawn(pawn):
	if pawn == null:
		return
	
	if not pawn_queues.has(pawn):
		return
	
	var command_queue = pawn_queues[pawn]
	command_queue.clear_queue()
	pawn_queues.erase(pawn)
	
	pawn_removed.emit(pawn)

## Add a task to the global queue
func add_task(task: WorkTask):
	global_queue.add_task(task)

## Assign a task to a specific pawn
func assign_task_to_pawn(task: WorkTask, pawn):
	if not pawn_queues.has(pawn):
		return false
	
	var command_queue = pawn_queues[pawn]
	
	# Check if pawn can accept manual tasks
	if not command_queue.accepts_manual_tasks():
		return false
	
	# Add to pawn's queue
	command_queue.add_task(task)
	
	# Mark as manual
	task.is_manual = true
	
	return true

## Assign a task to a specific pawn with high priority
func assign_task_to_pawn_front(task: WorkTask, pawn):
	if not pawn_queues.has(pawn):
		return false
	
	var command_queue = pawn_queues[pawn]
	
	# Check if pawn can accept manual tasks
	if not command_queue.accepts_manual_tasks():
		return false
	
	# Add to front of pawn's queue
	command_queue.add_task_front(task)
	
	# Mark as manual
	task.is_manual = true
	
	return true

## Process automatic assignments
func process_assignments():
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if current_time - last_assignment_time < assignment_interval:
		return
	
	last_assignment_time = current_time
	
	for pawn in pawn_queues:
		var command_queue = pawn_queues[pawn]
		
		# Skip if pawn doesn't accept auto tasks
		if not command_queue.accepts_auto_tasks():
			continue
		
		# Skip if pawn has a current task
		if command_queue.current_task != null:
			continue
		
		# Get best task for this pawn
		var best_task = global_queue.get_best_task_for_pawn(pawn)
		if best_task == null:
			continue
		
		# Assign the task
		if global_queue.assign_task_to_pawn(best_task, pawn):
			command_queue.add_task(best_task)

## Execute immediate task
func execute_immediate_task(task: WorkTask):
	if task == null:
		return
	
	if not task.is_immediate:
		return
	
	task.execute_direct()
	
	# Mark as completed in global queue
	global_queue.complete_task(task, null)

## Get command queue for a pawn
func get_pawn_queue(pawn) -> CommandQueue:
	if pawn_queues.has(pawn):
		return pawn_queues[pawn]
	return null

## Get all pawns
func get_all_pawns() -> Array:
	return pawn_queues.keys()

## Get all tasks for a pawn
func get_pawn_tasks(pawn) -> Array[WorkTask]:
	var command_queue = get_pawn_queue(pawn)
	if command_queue == null:
		return []
	
	return command_queue.get_all_tasks()

## Clear all tasks
func clear_all_tasks():
	global_queue.clear_all_tasks()
	
	for command_queue in pawn_queues.values():
		command_queue.clear_queue()

## Set assignment mode
func set_assignment_mode(mode: AssignmentMode):
	assignment_mode = mode

## Get assignment mode
func get_assignment_mode() -> AssignmentMode:
	return assignment_mode

## Set assignment interval
func set_assignment_interval(interval: float):
	assignment_interval = interval

## Get assignment interval
func get_assignment_interval() -> float:
	return assignment_interval

## Get dispatcher statistics
func get_dispatcher_stats() -> Dictionary:
	var total_pawns = pawn_queues.size()
	var total_queued_tasks = 0
	
	for command_queue in pawn_queues.values():
		total_queued_tasks += command_queue.get_queue_size()
	
	var global_stats = global_queue.get_queue_stats()
	
	return {
		"total_pawns": total_pawns,
		"total_queued_tasks": total_queued_tasks,
		"assignment_mode": assignment_mode,
		"assignment_interval": assignment_interval,
		"global_queue": global_stats
	}

## Signal handlers
func _on_global_task_assigned(task: WorkTask, pawn):
	task_assigned.emit(task, pawn)

func _on_global_task_completed(task: WorkTask, pawn):
	task_completed.emit(task, pawn)

func _on_global_task_failed(task: WorkTask, pawn):
	task_failed.emit(task, pawn)

func _on_pawn_task_started(task: WorkTask):
	# Handle pawn task started
	pass

func _on_pawn_task_completed(task: WorkTask):
	# Handle pawn task completed
	pass

func _on_pawn_task_failed(task: WorkTask):
	# Handle pawn task failed
	pass 