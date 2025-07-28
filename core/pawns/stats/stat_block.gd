extends Resource
class_name StatBlock

@export var movement_speed: float = 1.0
@export var manipulation: float = 1.0
@export var sight: float = 1.0

func apply_modifiers(mods: Dictionary):
	for key in mods:
		if has_stat(key):
			self.set(key, self.get(key) * mods[key])

func has_stat(stat_name: String) -> bool:
	for prop in get_property_list():
		if prop.name == stat_name:
			return true
	return false
