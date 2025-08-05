# Файл: addons/deep_thought/core/resource/game_resource.gd
class_name GameResource
extends RefCounted

var definition_id: String
var amount: int

func _init(p_definition_id: String, p_amount: int):
	self.definition_id = p_definition_id
	self.amount = p_amount
