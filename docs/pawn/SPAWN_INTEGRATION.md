# 🎮 Интеграция системы спауна пешек

## 📋 **Обзор**

Система спауна пешек интегрирована в сцену Plot и позволяет автоматически и вручную создавать пешки в мире.

## 🔧 **Компоненты системы:**

### **1. SpawnManager**
- **Расположение**: `addons/deep_thought/core/pawns/spawn/spawn_manager.gd`
- **Функция**: Основной координатор спауна пешек
- **Настройки**:
  - `pawn_scene`: Сцена пешки для спауна
  - `world_generator`: Ссылка на генератор мира
  - `auto_spawn_on_ready`: Автоматический спаун при загрузке
  - `spawn_count`: Количество пешек для спауна
  - `spawn_height_offset`: Высота спауна над поверхностью

### **2. SpawnController**
- **Расположение**: `scripts/spawn_controller.gd`
- **Функция**: Управление спауном через клавиши
- **Управление**:
  - `S` - Спаун одной пешки
  - `M` - Спаун нескольких пешек
  - `C` - Очистить всех пешек
  - `I` - Информация о спауне

## 🚀 **Быстрый старт:**

### **1. Настройка в сцене Plot:**
```gdscript
# SpawnManager уже настроен в сцене
# - pawn_scene = Pawn.tscn
# - world_generator = Plot (WorldPreview)
# - auto_spawn_on_ready = true
# - spawn_count = 3
# - spawn_height_offset = 2.0
```

### **2. Управление через клавиши:**
```
S - Спаун одной пешки
M - Спаун нескольких пешек
C - Очистить всех пешек
I - Информация о спауне
```

### **3. Программное управление:**
```gdscript
# Получить SpawnManager
var spawn_manager = get_node("SpawnManager")

# Спаун пешек
spawn_manager.spawn_pawns(5)

# Спаун в конкретной позиции
spawn_manager.spawn_pawn_at_position(Vector3(0, 10, 0))

# Очистка
spawn_manager.clear_spawned_pawns()

# Информация
var info = spawn_manager.get_spawn_info()
print("Пешек: " + str(info.spawned_count))
```

## 📁 **Структура файлов:**

```
scenes/world/Plot.tscn
├── SpawnManager (управление спауном)
├── SpawnController (управление клавишами)
└── WorldPreview (генератор мира)

scenes/pawns/Pawn.tscn
├── CharacterBody3D (физика)
├── PawnVisual (визуал)
├── PawnController (движение)
└── AutoCollisionSystem (коллизии)

scripts/spawn_controller.gd
└── Управление через клавиши
```

## ⚙️ **Настройка:**

### **Автоматический спаун:**
```gdscript
# В SpawnManager
auto_spawn_on_ready = true
spawn_count = 3
spawn_height_offset = 2.0
```

### **Ручной спаун:**
```gdscript
# Через SpawnController
# Нажмите S для спауна одной пешки
# Нажмите M для спауна нескольких пешек
```

### **Настройка позиции спауна:**
```gdscript
# Спаун в центре мира
spawn_manager.spawn_pawn_at_position(Vector3(0, 10, 0))

# Спаун в случайной позиции
var random_pos = Vector3(randf_range(-50, 50), 10, randf_range(-50, 50))
spawn_manager.spawn_pawn_at_position(random_pos)
```

## 🎯 **Использование в игре:**

### **1. Запуск сцены Plot:**
- Пешки автоматически появятся при загрузке
- Используйте клавиши для управления

### **2. Интеграция в другие сцены:**
```gdscript
# Добавить в любую сцену
@export var spawn_manager: SpawnManager

func _ready():
    spawn_manager.spawn_pawns(1)
```

### **3. Кастомизация:**
```gdscript
# Настройка параметров спауна
spawn_manager.spawn_height_offset = 5.0
spawn_manager.max_spawned_pawns = 20
spawn_manager.spawn_delay = 0.5
```

## 🔍 **Отладка:**

### **Логи:**
- Все действия логируются через Logger
- Проверьте консоль для информации

### **Проверка:**
```gdscript
# Проверка количества пешек
var info = spawn_manager.get_spawn_info()
print("Пешек в мире: " + str(info.spawned_count))

# Проверка настроек
print("Автоспаун: " + str(info.auto_spawn))
print("Максимум пешек: " + str(info.max_spawned))
```

## 🚨 **Возможные проблемы:**

### **1. Пешки не появляются:**
- Проверьте `pawn_scene` в SpawnManager
- Убедитесь, что `world_generator` назначен
- Проверьте логи на ошибки

### **2. Пешки падают под землю:**
- Увеличьте `spawn_height_offset` в SpawnManager
- Проверьте высоту поверхности в мире

### **3. Клавиши не работают:**
- Убедитесь, что SpawnController добавлен в сцену
- Проверьте, что `spawn_manager` назначен

## ✅ **Готово к использованию!**

Система спауна полностью интегрирована и готова к использованию. Просто запустите сцену Plot и используйте клавиши для управления спауном пешек. 