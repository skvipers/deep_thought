extends Camera3D
class_name FlyCamera

@export var move_speed: float = 20.0
@export var mouse_sensitivity: float = 0.002
@export var boost_multiplier: float = 3.0
@export var input_enabled: bool = true

var velocity := Vector3.ZERO

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if not input_enabled:
		return
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotate_object_local(Vector3.RIGHT, -event.relative.y * mouse_sensitivity)
	
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	if not input_enabled:
		return
		
	var input_vector := Vector3.ZERO
	
	# Движение
	if Input.is_action_pressed("move_forward"):
		input_vector.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_vector.z += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y += 1
	if Input.is_action_pressed("move_down"):
		input_vector.y -= 1
	
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
