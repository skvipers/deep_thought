extends CharacterBody3D
class_name Pawn

const Prosthesis = preload("res://addons/deep_thought/core/pawns/parts/prosthesis.gd")
const BodyStructure = preload("res://addons/deep_thought/core/pawns/parts/body_structure.gd")
const PawnSkeletonData = preload("res://addons/deep_thought/core/pawns/skeleton/pawn_skeleton_data.gd")
const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@export var config: PawnConfig
@onready var visual := $Visual

var stats: StatBlock
var body: BodyStructure
var skeleton: Node3D  # Can be PawnSkeleton or AutoSkeletonController

# Task system integration
var job_priorities: Dictionary = {}
var skill_levels: Dictionary = {}
var current_task = null
var task_queue: Array = []
var is_working: bool = false
var work_target = null
var work_progress: float = 0.0

# Energy and fatigue system
var energy: float = 100.0
var max_energy: float = 100.0
var fatigue_rate: float = 1.0
var rest_rate: float = 2.0

func _ready():
	if config:
		Logger.info("PAWN", "Initializing pawn with config")
		stats = config.base_stats.duplicate()
		body = config.body_structure.duplicate()
		_apply_prosthetics()
		_initialize_task_system()
		
		if visual:
			visual.apply_body(body)
			if config:
				var skeleton_data = config.get_skeleton_data()
				if skeleton_data and visual.get_skeleton():
					visual.set_skeleton_data(skeleton_data)
					skeleton = visual.get_skeleton()
					Logger.debug("PAWN", "Skeleton initialized")
				else:
					Logger.warn("PAWN", "Failed to initialize skeleton")
		else:
			Logger.warn("PAWN", "No visual component found")
	else:
		Logger.warn("PAWN", "No config provided")

func _initialize_task_system():
	"""Initialize task system for this pawn"""
	Logger.debug("PAWN", "Initializing task system")
	
	# Initialize default job priorities
	job_priorities = {
		"firefighter": 3,
		"patient": 3,
		"doctor": 3,
		"rest": 3,
		"work": 3,
		"supervision": 3,
		"animal_breeder": 3,
		"cook": 3,
		"hunter": 3,
		"builder": 3,
		"farmer": 3,
		"miner": 3,
		"lumberjack": 3,
		"gardener": 3,
		"tailor": 3,
		"artist": 3,
		"craftsman": 3,
		"porter": 3,
		"cleaner": 3,
		"scientist": 3
	}
	
	# Initialize default skill levels
	skill_levels = {
		"firefighter": 1,
		"patient": 1,
		"doctor": 1,
		"rest": 1,
		"work": 1,
		"supervision": 1,
		"animal_breeder": 1,
		"cook": 1,
		"hunter": 1,
		"builder": 1,
		"farmer": 1,
		"miner": 1,
		"lumberjack": 1,
		"gardener": 1,
		"tailor": 1,
		"artist": 1,
		"craftsman": 1,
		"porter": 1,
		"cleaner": 1,
		"scientist": 1
	}

func _apply_prosthetics():
	"""Apply prosthetics to body parts"""
	Logger.debug("PAWN", "Applying prosthetics")
	for part_name in body.parts:
		var part = body.parts[part_name]
		if part.prosthesis:
			part.prosthesis.apply_to_part(part)
			Logger.debug("PAWN", "Applied prosthesis to " + part_name)

func set_pose(pose_name: String):
	"""Set pawn pose"""
	if visual:
		visual.set_pose(pose_name)
		Logger.debug("PAWN", "Set pose: " + pose_name)
	else:
		Logger.warn("PAWN", "No visual component for pose setting")

func get_default_pose() -> String:
	"""Returns default pose from skeleton"""
	if skeleton and skeleton.has_method("get_default_pose"):
		return skeleton.get_default_pose()
	return "idle"

func set_default_pose():
	"""Set default pose"""
	var default_pose = get_default_pose()
	set_pose(default_pose)
	Logger.debug("PAWN", "Set default pose: " + default_pose)

func get_bone_transform(bone_name: String) -> Transform3D:
	"""Returns bone transform"""
	if visual:
		return visual.get_bone_transform(bone_name)
	return Transform3D.IDENTITY

func set_bone_transform(bone_name: String, transform: Transform3D):
	"""Set bone transform"""
	if visual:
		visual.set_bone_transform(bone_name, transform)
		Logger.debug("PAWN", "Set bone transform: " + bone_name)

func get_skeleton() -> Node3D:
	"""Returns pawn skeleton"""
	return skeleton

func apply_damage_to_part(part_name: String, damage: int):
	"""Apply damage to body part"""
	if body.parts.has(part_name):
		var part = body.parts[part_name]
		part.current_health = max(0, part.current_health - damage)
		Logger.info("PAWN", "Applied " + str(damage) + " damage to " + part_name + " (health: " + str(part.current_health) + ")")
		
		# Update visual
		if visual:
			visual.apply_body(body)
	else:
		Logger.warn("PAWN", "Body part not found: " + part_name)

func heal_part(part_name: String, heal_amount: int):
	"""Heal body part"""
	if body.parts.has(part_name):
		var part = body.parts[part_name]
		part.current_health = min(part.max_health, part.current_health + heal_amount)
		Logger.info("PAWN", "Healed " + part_name + " by " + str(heal_amount) + " (health: " + str(part.current_health) + ")")
		
		# Update visual
		if visual:
			visual.apply_body(body)
	else:
		Logger.warn("PAWN", "Body part not found: " + part_name)

func install_prosthesis(part_name: String, prosthesis: Prosthesis):
	"""Install prosthesis on body part"""
	if body.parts.has(part_name):
		var part = body.parts[part_name]
		part.prosthesis = prosthesis
		Logger.info("PAWN", "Installed prosthesis on " + part_name)
		
		# Update visual
		if visual:
			visual.apply_body(body)
	else:
		Logger.warn("PAWN", "Body part not found: " + part_name)

func get_part_health(part_name: String) -> int:
	"""Returns body part health"""
	if body.parts.has(part_name):
		return body.parts[part_name].current_health
	return 0

func get_part_max_health(part_name: String) -> int:
	"""Returns maximum body part health"""
	if body.parts.has(part_name):
		return body.parts[part_name].max_health
	return 0

# Methods for hybrid skeleton
func set_skeleton_bone_pose(bone_name: String, pose_name: String):
	"""Sets pose for Skeleton3D bone"""
	if visual:
		visual.set_skeleton_bone_pose(bone_name, pose_name)

func set_skeleton_bone_joint_rotation(bone_name: String, joint_index: int, rotation: Vector3):
	"""Sets joint rotation for Skeleton3D bone"""
	if visual:
		visual.set_skeleton_bone_joint_rotation(bone_name, joint_index, rotation)

func get_bone_type(bone_name: String) -> String:
	"""Returns bone type"""
	if visual:
		return visual.get_bone_type(bone_name)
	return "unknown"

func get_skeleton_bone(bone_name: String) -> Skeleton3D:
	"""Returns Skeleton3D bone"""
	if visual:
		return visual.get_skeleton_bone(bone_name)
	return null

func get_simple_bone(bone_name: String) -> Node3D:
	"""Returns simple Node3D bone"""
	if visual:
		return visual.get_simple_bone(bone_name)
	return null

# Task system methods
func get_job_priority(job_type: String) -> int:
	"""Get priority for a specific job type"""
	if job_priorities.has(job_type):
		return job_priorities[job_type]
	return 3  # Default priority

func set_job_priority(job_type: String, priority: int):
	"""Set priority for a specific job type"""
	job_priorities[job_type] = priority
	Logger.debug("PAWN", "Set " + job_type + " priority to " + str(priority))

func get_skill_level(skill_name: String) -> int:
	"""Get skill level for a specific skill"""
	if skill_levels.has(skill_name):
		return skill_levels[skill_name]
	return 1

func set_skill_level(skill_name: String, level: int):
	"""Set skill level for a specific skill"""
	skill_levels[skill_name] = level
	Logger.debug("PAWN", "Set " + skill_name + " skill to " + str(level))

func increase_skill_level(skill_name: String, amount: int = 1):
	"""Increase skill level"""
	var current_level = get_skill_level(skill_name)
	set_skill_level(skill_name, current_level + amount)

func can_perform_job(job_type: String) -> bool:
	"""Check if pawn can perform a specific job"""
	var skill_level = get_skill_level(job_type)
	return skill_level > 0 and is_healthy_enough() and energy > 20.0

func is_healthy_enough() -> bool:
	"""Check if pawn is healthy enough to work"""
	var critical_parts = ["head", "torso"]
	
	for part_name in critical_parts:
		if get_part_health(part_name) <= 0:
			return false
	
	return true

func get_energy_level() -> float:
	"""Get current energy level as percentage"""
	return energy / max_energy

func is_tired() -> bool:
	"""Check if pawn is tired"""
	return energy < 30.0

func consume_energy(amount: float):
	"""Consume energy"""
	energy = max(0.0, energy - amount)

func restore_energy(amount: float):
	"""Restore energy"""
	energy = min(max_energy, energy + amount)

func start_work(task, target = null):
	"""Start working on a task"""
	if not can_perform_job(task.job_type):
		Logger.warn("PAWN", "Cannot perform job: " + task.job_type)
		return false
	
	current_task = task
	work_target = target
	is_working = true
	work_progress = 0.0
	
	Logger.info("PAWN", "Started working on: " + task.job_type)
	return true

func stop_work():
	"""Stop current work"""
	if current_task:
		Logger.info("PAWN", "Stopped working on: " + current_task.job_type)
	
	current_task = null
	work_target = null
	is_working = false
	work_progress = 0.0

func update_work(delta: float):
	"""Update work progress"""
	if not is_working or not current_task:
		return
	
	# Consume energy while working
	consume_energy(fatigue_rate * delta)
	
	# Update work progress
	work_progress += delta * get_skill_level(current_task.job_type)
	
	# Check if work is complete
	if work_progress >= 1.0:
		complete_work()

func complete_work():
	"""Complete current work"""
	if not current_task:
		return
	
	# Increase skill level
	increase_skill_level(current_task.job_type, 1)
	
	Logger.info("PAWN", "Completed work: " + current_task.job_type)
	stop_work()

func _process(delta: float):
	"""Process pawn updates"""
	_update_energy(delta)
	update_work(delta)

func _update_energy(delta: float):
	"""Update energy levels"""
	if is_working:
		# Consume energy while working
		consume_energy(fatigue_rate * delta)
	else:
		# Restore energy while resting
		restore_energy(rest_rate * delta)
