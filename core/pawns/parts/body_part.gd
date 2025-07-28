extends Resource
class_name BodyPart

const Prosthesis = preload("res://addons/deep_thought/core/pawns/parts/prosthesis.gd")

@export var name: String
@export var max_health: int = 30
@export var current_health: int = 30
@export var bone_name: String
@export var type: String
@export var prosthesis: Prosthesis = null

func is_missing() -> bool:
	return current_health <= 0 and prosthesis == null
