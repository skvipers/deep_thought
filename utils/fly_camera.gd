extends Camera3D
class_name FlyCamera

@export var move_speed: float = 20.0
@export var mouse_sensitivity: float = 0.002
@export var zoom_sensitivity: float = 2.0
@export var boost_multiplier: float = 3.0
@export var input_enabled: bool = true

var velocity := Vector3.ZERO
var is_rotating: bool = false

func _ready():
	# Начинаем в режиме интерфейса (мышь свободна)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event):
	if not input_enabled:
		return
	
	# Обработка скролла для приближения/удаления
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Приближение
			var forward = -transform.basis.z
			position += forward * zoom_sensitivity
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Удаление
			var forward = -transform.basis.z
			position -= forward * zoom_sensitivity
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			# Начало/конец вращения
			if event.pressed:
				is_rotating = true
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				is_rotating = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Обработка вращения камеры при зажатом среднем колесике
	if event is InputEventMouseMotion and is_rotating:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotate_object_local(Vector3.RIGHT, -event.relative.y * mouse_sensitivity)

func _physics_process(delta):
	if not input_enabled:
		return
		
	var input_vector := Vector3.ZERO
	
	# Движение WASD
	if Input.is_action_pressed("move_forward"):
		input_vector.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_vector.z += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	
	input_vector = input_vector.normalized()
	
	# Применяем ускорение
	var speed = move_speed
	if Input.is_action_pressed("shift"):
		speed *= boost_multiplier
	
	# Преобразуем вектор в локальные координаты камеры
	velocity = (transform.basis * input_vector) * speed
	
	# Применяем движение
	position += velocity * delta

func set_input_enabled(enabled: bool):
	"""Enable or disable camera input"""
	input_enabled = enabled

func is_input_enabled() -> bool:
	"""Check if camera input is enabled"""
	return input_enabled
