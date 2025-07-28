extends Resource
class_name BodyStructure

const BodyPart = preload("res://addons/deep_thought/core/pawns/parts/body_part.gd")

@export var parts: Dictionary = {} # name: BodyPart

func get_stat_modifiers() -> Dictionary:
	var result := {}
	for part in parts.values():
		if part.prosthesis:
			result.merge(part.prosthesis.stat_mods, true)
	return result
