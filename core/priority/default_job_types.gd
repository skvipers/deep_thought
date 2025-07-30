extends RefCounted
class_name DefaultJobTypes

## Demo class for initializing default job types
## This is optional and can be used for demonstration purposes
## Games can create their own job type initialization

## Initialize default job types for demonstration
static func initialize_default_job_types() -> void:
	PrioritySystem.register_job_type("doctor", "Medical", PrioritySystem.priority_scale_max, "Medical treatment and healing")
	PrioritySystem.register_job_type("construction", "Construction", PrioritySystem.priority_scale_default + 1, "Building and construction work")
	PrioritySystem.register_job_type("mining", "Mining", PrioritySystem.priority_scale_default + 1, "Resource extraction and mining")
	PrioritySystem.register_job_type("cooking", "Cooking", PrioritySystem.priority_scale_default + 1, "Food preparation and cooking")
	PrioritySystem.register_job_type("hauling", "Hauling", PrioritySystem.priority_scale_default, "Item transportation and hauling")
	PrioritySystem.register_job_type("cleaning", "Cleaning", PrioritySystem.priority_scale_default, "Area maintenance and cleaning")
	PrioritySystem.register_job_type("farming", "Farming", PrioritySystem.priority_scale_default, "Crop cultivation and farming")
	PrioritySystem.register_job_type("research", "Research", PrioritySystem.priority_scale_default - 1, "Technology research and development")
	PrioritySystem.register_job_type("crafting", "Crafting", PrioritySystem.priority_scale_default, "Item creation and crafting")
	PrioritySystem.register_job_type("guard", "Security", PrioritySystem.priority_scale_max, "Security and guard duties")

## Clear all default job types
static func clear_default_job_types() -> void:
	var default_job_ids = ["doctor", "construction", "mining", "cooking", "hauling", "cleaning", "farming", "research", "crafting", "guard"]
	for job_id in default_job_ids:
		PrioritySystem.unregister_job_type(job_id)

## Get list of default job type IDs
static func get_default_job_type_ids() -> Array[String]:
	return ["doctor", "construction", "mining", "cooking", "hauling", "cleaning", "farming", "research", "crafting", "guard"] 