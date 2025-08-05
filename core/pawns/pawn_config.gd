extends Resource
class_name PawnConfig

const StatBlock = preload("res://addons/deep_thought/core/pawns/stats/stat_block.gd")
const BodyStructure = preload("res://addons/deep_thought/core/pawns/parts/body_structure.gd")
const PawnSkeletonData = preload("res://addons/deep_thought/core/pawns/skeleton/pawn_skeleton_data.gd")
const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@export var base_stats: StatBlock
@export var body_structure: BodyStructure
@export var skeleton_type: String = "humanoid"  # "humanoid", "hybrid", "advanced", "flexible", "quadruped"

@export_group("Task System")
@export var default_job_priorities: Dictionary = {
	"firefighter": 3, "patient": 3, "doctor": 3, "rest": 3, "work": 3, 
	"supervision": 3, "animal_breeder": 3, "cook": 3, "hunter": 3, "builder": 3, 
	"farmer": 3, "miner": 3, "lumberjack": 3, "gardener": 3, "tailor": 3, 
	"artist": 3, "craftsman": 3, "porter": 3, "cleaner": 3, "scientist": 3
}
@export var default_skill_levels: Dictionary = {
	"firefighter": 1, "patient": 1, "doctor": 1, "rest": 1, "work": 1,
	"supervision": 1, "animal_breeder": 1, "cook": 1, "hunter": 1, "builder": 1,
	"farmer": 1, "miner": 1, "lumberjack": 1, "gardener": 1, "tailor": 1,
	"artist": 1, "craftsman": 1, "porter": 1, "cleaner": 1, "scientist": 1
}

@export_group("Health")
@export var critical_parts: Array[String] = ["head", "torso"]


func get_skeleton_data() -> PawnSkeletonData:
	"""Creates skeleton data based on type"""
	Logger.debug("PAWN", "Creating skeleton data for type: " + skeleton_type)
	
	match skeleton_type:
		"humanoid": 
			var skeleton = SkeletonFactory.create_humanoid_skeleton()
			Logger.info("PAWN", "Created humanoid skeleton")
			return skeleton
		"hybrid": 
			var skeleton = SkeletonFactory.create_hybrid_humanoid_skeleton()
			Logger.info("PAWN", "Created hybrid skeleton")
			return skeleton
		"advanced": 
			var skeleton = SkeletonFactory.create_advanced_humanoid_skeleton()
			Logger.info("PAWN", "Created advanced skeleton")
			return skeleton
		"flexible": 
			var skeleton = SkeletonFactory.create_flexible_creature_skeleton()
			Logger.info("PAWN", "Created flexible skeleton")
			return skeleton
		"quadruped": 
			var skeleton = SkeletonFactory.create_quadruped_skeleton()
			Logger.info("PAWN", "Created quadruped skeleton")
			return skeleton
		_: 
			var skeleton = SkeletonFactory.create_humanoid_skeleton()
			Logger.warn("PAWN", "Unknown skeleton type: " + skeleton_type + ", using humanoid")
			return skeleton
