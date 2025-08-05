class_name ProductionComponent
extends LogicComponent

## Компонент для производства ресурсов

@export var production_rate: float = 1.0  ## Ресурсов в секунду
@export var production_type: String = "food"
@export var max_storage: int = 100
@export var current_storage: int = 0

var time_since_last_production: float = 0.0

func on_init():
	component_name = "production"
	print("ProductionComponent initialized for: ", production_type)

func on_tick(delta: float):
	if not is_enabled:
		return
	
	time_since_last_production += delta
	
	# Производим ресурсы каждую секунду
	if time_since_last_production >= 1.0:
		_produce_resources()
		time_since_last_production = 0.0

func on_interact(actor):
	if current_storage > 0:
		# Отдаем ресурсы актору
		var amount_to_give = min(current_storage, 10)  # Даем по 10 за раз
		current_storage -= amount_to_give
		print("Gave ", amount_to_give, " ", production_type, " to actor")
		
		# Здесь можно добавить логику передачи ресурсов актору
		# actor.add_resource(production_type, amount_to_give)

func _produce_resources():
	if current_storage < max_storage:
		var amount_to_produce = int(production_rate)
		current_storage = min(current_storage + amount_to_produce, max_storage)
		print("Produced ", amount_to_produce, " ", production_type)

func get_storage_percentage() -> float:
	return float(current_storage) / float(max_storage) * 100.0

func is_storage_full() -> bool:
	return current_storage >= max_storage

func is_storage_empty() -> bool:
	return current_storage <= 0 
