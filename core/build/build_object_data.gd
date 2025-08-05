class_name BuildObjectData
extends Resource

## Ресурс, описывающий объект, который можно построить

@export var id: String = ""
@export var name: String = ""
@export var mesh: Mesh
@export var size: Vector3i = Vector3i.ONE
@export var icon: Texture2D
@export var is_interactable: bool = false
@export var logic_components: Array[PackedScene] = []
@export var priority: int = 0
@export var tags: Array[String] = []
@export var build_cost: Dictionary = {}
@export var build_time: float = 1.0
@export var category: String = ""
@export var description: String = ""

## Создает BuildObject из данных
func create_build_object() -> BuildObject:
	var object = BuildObject.new()
	object.init_from_data(self)
	return object 