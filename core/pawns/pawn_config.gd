extends Resource
class_name PawnConfig

const SkeletonFactory = preload("res://addons/deep_thought/core/factories/SkeletonFactory.gd")
const StatBlock = preload("res://addons/deep_thought/core/pawns/stats/stat_block.gd")
const BodyStructure = preload("res://addons/deep_thought/core/pawns/parts/body_structure.gd")
const PawnSkeletonData = preload("res://addons/deep_thought/core/pawns/skeleton/pawn_skeleton_data.gd")
const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

@export var base_stats: StatBlock
@export var body_structure: BodyStructure
@export var skeleton_type: String = "humanoid"  # "humanoid", "hybrid", "advanced", "flexible", "quadruped"

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
