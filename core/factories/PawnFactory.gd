class_name PawnFactory

static func create_pawn(config: PawnConfig) -> Pawn:
	var pawn = Pawn.new()
	pawn.config = config
	pawn.stats = config.base_stats.duplicate()
	pawn.body = config.body_structure.duplicate()
	pawn._apply_prosthetics()
	if pawn.has_node("Visual"):
		pawn.visual = pawn.get_node("Visual")
		pawn.visual.apply_body(pawn.body)
	return pawn 