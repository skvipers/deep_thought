extends RefCounted
class_name ExampleCommands

## Example task implementations for demonstration
## These show how to create specific task types

const WorkTask = preload("res://addons/deep_thought/core/priority/work_task.gd")
const ImmediateCommand = preload("res://addons/deep_thought/core/priority/immediate_command.gd")

## Construction task
class ConstructionTask extends WorkTask:
	var target_position: Vector3
	var construction_type: String
	var progress_per_tick: float = 0.1
	
	func _init(cmd_description: String, cmd_job_type: String, cmd_priority: int, pos: Vector3, construction: String):
		super._init(cmd_job_type, cmd_priority)
		description = cmd_description
		target_position = pos
		construction_type = construction
	
	func execute(pawn):
		if not can_be_executed_by(pawn):
			fail()
			return
		
		start_execution()
		
		# Simulate construction progress
		update_progress(progress + progress_per_tick)
		
		# Complete when progress reaches 1.0
		if progress >= 1.0:
			complete()

## Mining task
class MiningTask extends WorkTask:
	var target_position: Vector3
	var resource_type: String
	var mining_speed: float = 0.15
	
	func _init(cmd_description: String, cmd_job_type: String, cmd_priority: int, pos: Vector3, resource: String):
		super._init(cmd_job_type, cmd_priority)
		description = cmd_description
		target_position = pos
		resource_type = resource
	
	func execute(pawn):
		if not can_be_executed_by(pawn):
			fail()
			return
		
		start_execution()
		
		# Simulate mining progress
		update_progress(progress + mining_speed)
		
		# Complete when progress reaches 1.0
		if progress >= 1.0:
			complete()

## Hauling task
class HaulingTask extends WorkTask:
	var source_position: Vector3
	var target_position: Vector3
	var item_type: String
	var hauling_speed: float = 0.2
	
	func _init(cmd_description: String, cmd_job_type: String, cmd_priority: int, source: Vector3, target: Vector3, item: String):
		super._init(cmd_job_type, cmd_priority)
		description = cmd_description
		source_position = source
		target_position = target
		item_type = item
	
	func execute(pawn):
		if not can_be_executed_by(pawn):
			fail()
			return
		
		start_execution()
		
		# Simulate hauling progress
		update_progress(progress + hauling_speed)
		
		# Complete when progress reaches 1.0
		if progress >= 1.0:
			complete()

## Medical task
class MedicalTask extends WorkTask:
	var patient_pawn
	var treatment_type: String
	var healing_speed: float = 0.25
	
	func _init(cmd_description: String, cmd_job_type: String, cmd_priority: int, patient, treatment: String):
		super._init(cmd_job_type, cmd_priority)
		description = cmd_description
		patient_pawn = patient
		treatment_type = treatment
	
	func execute(pawn):
		if not can_be_executed_by(pawn):
			fail()
			return
		
		start_execution()
		
		# Simulate healing progress
		update_progress(progress + healing_speed)
		
		# Complete when progress reaches 1.0
		if progress >= 1.0:
			complete()

## Cooking task
class CookingTask extends WorkTask:
	var recipe_name: String
	var ingredients: Array
	var cooking_speed: float = 0.3
	
	func _init(cmd_description: String, cmd_job_type: String, cmd_priority: int, recipe: String, ingredients_list: Array):
		super._init(cmd_job_type, cmd_priority)
		description = cmd_description
		recipe_name = recipe
		ingredients = ingredients_list
	
	func execute(pawn):
		if not can_be_executed_by(pawn):
			fail()
			return
		
		start_execution()
		
		# Simulate cooking progress
		update_progress(progress + cooking_speed)
		
		# Complete when progress reaches 1.0
		if progress >= 1.0:
			complete()

## Farming task
class FarmingTask extends WorkTask:
	var crop_type: String
	var field_position: Vector3
	var farming_speed: float = 0.2
	
	func _init(cmd_description: String, cmd_job_type: String, cmd_priority: int, crop: String, pos: Vector3):
		super._init(cmd_job_type, cmd_priority)
		description = cmd_description
		crop_type = crop
		field_position = pos
	
	func execute(pawn):
		if not can_be_executed_by(pawn):
			fail()
			return
		
		start_execution()
		
		# Simulate farming progress
		update_progress(progress + farming_speed)
		
		# Complete when progress reaches 1.0
		if progress >= 1.0:
			complete()

## Research task
class ResearchTask extends WorkTask:
	var research_topic: String
	var research_speed: float = 0.1
	
	func _init(cmd_description: String, cmd_job_type: String, cmd_priority: int, topic: String):
		super._init(cmd_job_type, cmd_priority)
		description = cmd_description
		research_topic = topic
	
	func execute(pawn):
		if not can_be_executed_by(pawn):
			fail()
			return
		
		start_execution()
		
		# Simulate research progress
		update_progress(progress + research_speed)
		
		# Complete when progress reaches 1.0
		if progress >= 1.0:
			complete()

## Guard task
class GuardTask extends WorkTask:
	var guard_position: Vector3
	var guard_radius: float
	var guard_duration: float = 60.0
	var guard_start_time: float = 0.0
	
	func _init(cmd_description: String, cmd_job_type: String, cmd_priority: int, pos: Vector3, radius: float):
		super._init(cmd_job_type, cmd_priority)
		description = cmd_description
		guard_position = pos
		guard_radius = radius
	
	func execute(pawn):
		if not can_be_executed_by(pawn):
			fail()
			return
		
		start_execution()
		
		# Check if guard duration has elapsed
		var current_time = Time.get_ticks_msec() / 1000.0
		if guard_start_time == 0.0:
			guard_start_time = current_time
		
		if current_time - guard_start_time >= guard_duration:
			complete()
		else:
			# Update progress based on time elapsed
			var elapsed = current_time - guard_start_time
			update_progress(elapsed / guard_duration)

## Utility functions for creating tasks
static func create_construction_task(description: String, priority: int, position: Vector3, construction: String) -> ConstructionTask:
	return ConstructionTask.new(description, "construction", priority, position, construction)

static func create_mining_task(description: String, priority: int, position: Vector3, resource: String) -> MiningTask:
	return MiningTask.new(description, "mining", priority, position, resource)

static func create_hauling_task(description: String, priority: int, source: Vector3, target: Vector3, item: String) -> HaulingTask:
	return HaulingTask.new(description, "hauling", priority, source, target, item)

static func create_medical_task(description: String, priority: int, patient, treatment: String) -> MedicalTask:
	return MedicalTask.new(description, "doctor", priority, patient, treatment)

static func create_cooking_task(description: String, priority: int, recipe: String, ingredients: Array) -> CookingTask:
	return CookingTask.new(description, "cooking", priority, recipe, ingredients)

static func create_farming_task(description: String, priority: int, crop: String, position: Vector3) -> FarmingTask:
	return FarmingTask.new(description, "farming", priority, crop, position)

static func create_research_task(description: String, priority: int, topic: String) -> ResearchTask:
	return ResearchTask.new(description, "research", priority, topic)

static func create_guard_task(description: String, priority: int, position: Vector3, radius: float) -> GuardTask:
	return GuardTask.new(description, "guard", priority, position, radius) 