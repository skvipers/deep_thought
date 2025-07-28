extends Resource
class_name StarConfig

@export var name: String = "Unnamed Star"
@export var light_color: Color = Color(1, 1, 1)
@export var intensity: float = 1.0
@export var size: float = 5.0
@export var temperature: float = 5778.0
@export var direction: Vector3 = Vector3(0, 0, 1)
@export var distance: float = 50.0

func get_color_by_temperature() -> Color:
	if temperature < 3700:    # Красные карлики (M-класс)
		return Color(1.0, 0.4, 0.2)
	elif temperature < 5200:  # Оранжевые звёзды (K-класс) 
		return Color(1.0, 0.7, 0.4)
	elif temperature < 6000:  # Жёлтые звёзды (G-класс) - как наше Солнце
		return Color(1.0, 0.95, 0.8)
	elif temperature < 7500:  # Бело-жёлтые (F-класс)
		return Color(1.0, 1.0, 0.9)
	elif temperature < 10000: # Белые звёзды (A-класс)
		return Color(0.9, 0.95, 1.0)
	elif temperature < 30000: # Голубо-белые (B-класс)
		return Color(0.7, 0.8, 1.0)
	else:                     # Голубые гиганты (O-класс)
		return Color(0.6, 0.7, 1.0)
