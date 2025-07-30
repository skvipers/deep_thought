# 🎮 Система спауна пешек

## 🎯 **Обзор системы**

Система спауна пешек предоставляет гибкие стратегии для размещения пешек в мире:
- **Центральный спаун** - в центре мира
- **Случайный спаун в области** - в указанной области
- **Спаун на краю** - на краю мира с указанным расстоянием
- **Кастомные стратегии** - создание собственных стратегий

## 📁 **Структура системы:**

```
SpawnSystem/
├── spawn_strategy.gd (базовый класс)
├── center_spawn_strategy.gd
├── random_area_spawn_strategy.gd
├── edge_spawn_strategy.gd
└── spawn_manager.gd (координатор)
```

## 🚀 **Быстрый старт:**

### **1. Создание SpawnManager:**
```gdscript
# В сцене игры
var spawn_manager = SpawnManager.new()
spawn_manager.pawn_scene = preload("res://scenes/pawn_hybrid.tscn")
spawn_manager.world_generator = world_generator  # Ваш генератор мира
add_child(spawn_manager)
```

### **2. Простые стратегии спауна:**
```gdscript
# Спаун в центре
spawn_manager.spawn_at_center()

# Спаун в случайной области
spawn_manager.spawn_in_random_area(Vector3(0, 0, 0), Vector3(100, 0, 100))

# Спаун на краю
spawn_manager.spawn_at_edge(10.0, "random")
```

### **3. Множественный спаун:**
```gdscript
# Спаун нескольких пешек
spawn_manager.spawn_count = 5
spawn_manager.spawn_pawns()

# Или с задержкой
spawn_manager.spawn_delay = 0.5
spawn_manager.spawn_pawns(3)
```

## 🎯 **Стратегии спауна:**

### **1. CenterSpawnStrategy - Спаун в центре**
```gdscript
var center_strategy = CenterSpawnStrategy.new()
center_strategy.center_offset = Vector3(0, 0, 0)  # Смещение от центра
center_strategy.use_world_center = true  # Использовать центр мира
center_strategy.spawn_height_offset = 1.0  # Высота над поверхностью

spawn_manager.spawn_pawn_with_strategy(center_strategy)
```

### **2. RandomAreaSpawnStrategy - Случайный спаун в области**
```gdscript
var random_strategy = RandomAreaSpawnStrategy.new()
random_strategy.area_center = Vector3(0, 0, 0)  # Центр области
random_strategy.area_size = Vector3(100, 0, 100)  # Размер области
random_strategy.area_radius = 50.0  # Или радиус для круглой области
random_strategy.use_world_center = true  # Использовать центр мира как центр области

spawn_manager.spawn_pawn_with_strategy(random_strategy)
```

### **3. EdgeSpawnStrategy - Спаун на краю**
```gdscript
var edge_strategy = EdgeSpawnStrategy.new()
edge_strategy.distance_from_edge = 10.0  # Расстояние от края
edge_strategy.edge_side = "random"  # "north", "south", "east", "west", "random"
edge_strategy.use_circular_edge = false  # Использовать круглый край

spawn_manager.spawn_pawn_with_strategy(edge_strategy)
```

## 🎮 **Использование в игре:**

### **1. Настройка в сцене:**
```gdscript
# В основной сцене игры
@export var spawn_manager: SpawnManager
@export var world_generator: Node3D

func _ready():
	spawn_manager.pawn_scene = preload("res://scenes/pawn_hybrid.tscn")
	spawn_manager.world_generator = world_generator
	
	# Автоматический спаун при загрузке
	spawn_manager.auto_spawn_on_ready = true
	spawn_manager.spawn_count = 3
```

### **2. Интерактивный спаун:**
```gdscript
func _input(event):
	if event.is_action_pressed("spawn_center"):
		spawn_manager.spawn_at_center()
	
	elif event.is_action_pressed("spawn_random"):
		spawn_manager.spawn_in_random_area(Vector3(0, 0, 0), Vector3(200, 0, 200))
	
	elif event.is_action_pressed("spawn_edge"):
		spawn_manager.spawn_at_edge(15.0, "north")
```

### **3. Управление спауном:**
```gdscript
# Получение информации
var pawn_count = spawn_manager.get_spawned_pawn_count()
var pawns = spawn_manager.get_spawned_pawns()

# Очистка
spawn_manager.clear_spawned_pawns()

# Проверка валидности позиции
var is_valid = spawn_manager.is_spawn_position_valid(Vector3(10, 0, 20))
```

## 🔧 **Кастомные стратегии:**

### **Создание собственной стратегии:**
```gdscript
extends SpawnStrategy
class_name CustomSpawnStrategy

func get_spawn_position(world: Node3D, world_generator = null) -> Vector3:
	# Ваша логика определения позиции
	var position = Vector3(randf_range(-50, 50), 0, randf_range(-50, 50))
	position.y += spawn_height_offset
	return position

func validate_spawn_position(position: Vector3, world: Node3D, world_generator = null) -> bool:
	# Ваша логика валидации
	return position.length() < 100  # Например, только в радиусе 100
```

### **Использование кастомной стратегии:**
```gdscript
var custom_strategy = CustomSpawnStrategy.new()
custom_strategy.spawn_height_offset = 2.0
custom_strategy.max_spawn_attempts = 20

spawn_manager.spawn_pawn_with_strategy(custom_strategy)
```

## ⚙️ **Настройки валидации:**

### **Параметры валидации:**
```gdscript
# В любой стратегии
spawn_strategy.check_surface_validity = true
spawn_strategy.min_surface_angle = 0.0  # Минимальный угол поверхности
spawn_strategy.max_surface_angle = 45.0  # Максимальный угол поверхности
spawn_strategy.required_clearance = 1.0  # Требуемое пространство вокруг
spawn_strategy.max_spawn_attempts = 10  # Максимум попыток
```

### **Интеграция с генератором мира:**
```gdscript
# Генератор мира должен предоставлять методы:
# - get_world_center() -> Vector3
# - get_world_bounds() -> AABB
# - is_position_in_bounds(position: Vector3) -> bool

class WorldGenerator:
	func get_world_center() -> Vector3:
		return Vector3.ZERO
	
	func get_world_bounds() -> AABB:
		return AABB(Vector3(-1000, 0, -1000), Vector3(2000, 100, 2000))
	
	func is_position_in_bounds(position: Vector3) -> bool:
		var bounds = get_world_bounds()
		return bounds.has_point(position)
```

## 📊 **Производительность:**

### **Оптимизации:**
- **Кэширование позиций** - избегайте повторных вычислений
- **Ограничение попыток** - настройте `max_spawn_attempts`
- **Отключение валидации** - для статичных миров
- **Пакетный спаун** - используйте `spawn_pawns()` вместо множественных вызовов

### **Настройки производительности:**
```gdscript
# Быстрый спаун без валидации
spawn_strategy.check_surface_validity = false
spawn_strategy.max_spawn_attempts = 1

# Медленный спаун с полной валидацией
spawn_strategy.check_surface_validity = true
spawn_strategy.max_spawn_attempts = 20
spawn_strategy.required_clearance = 2.0
```

## 🎯 **Примеры использования:**

### **1. Спаун игрока в центре:**
```gdscript
func spawn_player():
	var center_strategy = CenterSpawnStrategy.new()
	center_strategy.spawn_height_offset = 2.0
	spawn_manager.spawn_pawn_with_strategy(center_strategy)
```

### **2. Спаун NPC в случайных местах:**
```gdscript
func spawn_npcs(count: int):
	for i in range(count):
		var random_strategy = RandomAreaSpawnStrategy.new()
		random_strategy.area_center = Vector3(0, 0, 0)
		random_strategy.area_size = Vector3(500, 0, 500)
		spawn_manager.spawn_pawn_with_strategy(random_strategy)
		await get_tree().create_timer(0.1).timeout
```

### **3. Спаун врагов на краю:**
```gdscript
func spawn_enemies():
	var sides = ["north", "south", "east", "west"]
	for side in sides:
		var edge_strategy = EdgeSpawnStrategy.new()
		edge_strategy.distance_from_edge = 20.0
		edge_strategy.edge_side = side
		spawn_manager.spawn_pawn_with_strategy(edge_strategy)
```

## 🚀 **Готово к использованию!**

Система спауна пешек предоставляет гибкие и мощные инструменты для размещения персонажей в мире. Поддерживает различные стратегии, валидацию позиций и интеграцию с генераторами мира. 
