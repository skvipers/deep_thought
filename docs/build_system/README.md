# Строительная система Deep Thought

## Обзор

Строительная система предоставляет полный фреймворк для создания, размещения и управления строительными объектами в игровом мире. Система интегрируется с существующими компонентами Deep Thought: системой приоритетов, системой времени и другими.

## Быстрый старт

### 1. Инициализация системы

```gdscript
# Создаем менеджер строительной системы
var build_system = BuildSystemManager.new()
build_system.initialize(Vector3i(100, 10, 100))

# Устанавливаем ссылки на другие системы
build_system.set_system_references(priority_system, tick_manager, terrain_grid)
```

### 2. Создание объекта

```gdscript
# Создаем и размещаем дом
var house = build_system.create_and_place_object("house", Vector3i(10, 0, 10))
if house != null:
    print("Дом размещен успешно")
```

### 3. Взаимодействие с объектами

```gdscript
# Выполняем взаимодействие
var success = build_system.perform_interaction(player, Vector3i(10, 0, 10))
if success:
    print("Взаимодействие выполнено")
```

### 4. Обновление системы

```gdscript
func _process(delta):
    build_system.update(delta)
```

## Основные компоненты

### BuildObject
Базовый класс для всех строительных объектов.

**Ключевые возможности:**
- Размер и позиция в 3D пространстве
- Прогресс строительства
- Поворот объекта
- Теги и категоризация
- Стоимость строительства

### InteractableObject
Наследуется от BuildObject, добавляет:
- Логические компоненты
- Взаимодействие с акторами
- Диапазон взаимодействия
- Разрешенные акторы

### LogicComponent
Модули поведения для интерактивных объектов:
- Инициализация и обновление
- Взаимодействие
- Приоритеты
- Активация/деактивация

### BuildGrid
Управление размещением объектов:
- Размещение и удаление объектов
- Проверка занятости позиций
- Поддержка многоблочных объектов
- Ленивое создание ячеек

### OccupancyManager
Проверка возможности размещения:
- Различные маски проверки
- Интеграция с рельефом
- Проверка соседних объектов
- Запас места

## Создание собственных объектов

### 1. Создание ресурса BuildObjectData

```gdscript
# Создайте .tres файл в data/build_objects/
# Установите свойства: id, name, size, mesh, icon и т.д.
```

### 2. Создание логического компонента

```gdscript
class_name MyComponent
extends LogicComponent

@export var my_property: String = ""

func on_init():
    component_name = "my_component"

func on_tick(delta: float):
    # Ваша логика здесь
    pass

func on_interact(actor):
    # Логика взаимодействия
    pass
```

### 3. Регистрация в фабрике

```gdscript
# Фабрика автоматически загружает все .tres файлы
# из папки data/build_objects/
```

## Интеграция с системами

### Система приоритетов

```gdscript
# Создание задачи строительства
var build_task = build_system.create_build_task(builder, "house", Vector3i(10, 0, 10))

# Создание задачи взаимодействия
var interaction_task = build_system.create_interaction_task(player, Vector3i(10, 0, 10))
```

### Система времени

```gdscript
# Объекты автоматически регистрируются для тиков
# Логические компоненты обновляются каждый тик
```

## Примеры использования

### Создание фермы с производством

```gdscript
# Создаем ферму
var farm = build_system.create_interactable_object("farm", Vector3i(20, 0, 20))

# Добавляем компонент производства
var production = ProductionComponent.new()
production.production_type = "food"
production.production_rate = 2.0
farm.add_logic_component(production)
```

### Проверка возможности размещения

```gdscript
# Проверяем, можно ли разместить объект
var can_place = build_system.can_place_object("house", Vector3i(10, 0, 10))

# Проверка с учетом соседних объектов
var can_place_with_neighbors = occupancy_manager.can_place_with_neighbors(
    Vector3i(10, 0, 10), 
    Vector3i(3, 2, 3), 
    ["road", "power_plant"]
)
```

### Получение статистики

```gdscript
var stats = build_system.get_statistics()
print("Всего объектов: ", stats.total_objects)
print("Завершенных построек: ", stats.completed_builds)
```

## Структура файлов

```
addons/deep_thought/
├── core/build/
│   ├── build_object.gd              # Базовый класс объектов
│   ├── interactable_object.gd       # Интерактивные объекты
│   ├── logic_component.gd           # Логические компоненты
│   ├── build_cell.gd                # Ячейки сетки
│   ├── build_grid.gd                # Сетка размещения
│   ├── build_object_data.gd         # Данные объектов
│   ├── build_object_factory.gd      # Фабрика объектов
│   ├── build_system_manager.gd      # Основной менеджер
│   ├── components/
│   │   └── production_component.gd  # Пример компонента
│   └── integration/
│       ├── priority_integration.gd  # Интеграция с приоритетами
│       └── tick_integration.gd      # Интеграция с временем
├── managers/
│   └── occupancy_manager.gd         # Менеджер занятости
├── data/build_objects/
│   ├── house.tres                   # Пример объекта
│   └── farm.tres                    # Пример объекта
└── docs/build_system/
    ├── README.md                    # Эта документация
    └── build_system.md              # Подробная документация
```

## API Reference

### BuildSystemManager

**Основные методы:**
- `initialize(grid_size: Vector3i)` - инициализация
- `create_and_place_object(id: String, pos: Vector3i) -> BuildObject`
- `create_interactable_object(id: String, pos: Vector3i) -> InteractableObject`
- `remove_object(pos: Vector3i) -> bool`
- `get_object_at(pos: Vector3i) -> BuildObject`
- `can_place_object(id: String, pos: Vector3i) -> bool`
- `perform_interaction(actor: Object, pos: Vector3i) -> bool`
- `update(delta: float)` - обновление системы
- `get_statistics() -> Dictionary` - статистика
- `save_system_state() -> Dictionary` - сохранение
- `load_system_state(state: Dictionary)` - загрузка

**Сигналы:**
- `object_placed(object: BuildObject, position: Vector3i)`
- `object_removed(object: BuildObject, position: Vector3i)`
- `build_completed(object: BuildObject)`
- `interaction_performed(object: InteractableObject, actor: Object)`

### BuildObject

**Основные свойства:**
- `origin: Vector3i` - позиция
- `size: Vector3i` - размер
- `object_id: String` - ID
- `display_name: String` - название
- `priority: int` - приоритет
- `build_progress: float` - прогресс строительства
- `is_built: bool` - завершено ли строительство

**Основные методы:**
- `get_occupied_positions() -> Array[Vector3i]`
- `occupies_position(pos: Vector3i) -> bool`
- `set_position(new_origin: Vector3i)`
- `clone() -> BuildObject`
- `update_build_progress(delta: float)`

### InteractableObject

**Дополнительные свойства:**
- `logic_components: Array[LogicComponent]`
- `interaction_range: float`
- `can_interact: bool`
- `allowed_actors: Array`

**Дополнительные методы:**
- `interact(actor) -> bool`
- `update(delta: float)`
- `add_logic_component(component: LogicComponent)`
- `get_logic_component(name: String) -> LogicComponent`

### LogicComponent

**Основные свойства:**
- `priority: int`
- `is_enabled: bool`
- `component_name: String`
- `parent_object: InteractableObject`

**Основные методы:**
- `on_init()`
- `on_tick(delta: float)`
- `on_interact(actor)`
- `enable()`
- `disable()`

## Советы и рекомендации

### Производительность
- Используйте `get_objects_in_range()` для получения объектов в определенной области
- Регистрируйте объекты для тиков только при необходимости
- Используйте теги для быстрой фильтрации объектов

### Расширяемость
- Создавайте собственные компоненты для специфической логики
- Используйте наследование для создания специализированных объектов
- Добавляйте новые маски проверки в OccupancyManager

### Отладка
- Используйте `get_statistics()` для мониторинга системы
- Подключайтесь к сигналам для отслеживания событий
- Используйте `print()` в компонентах для отладки

## Известные ограничения

1. **Размер сетки**: Ограничен доступной памятью
2. **Количество объектов**: Производительность зависит от количества активных объектов
3. **Логические компоненты**: Не поддерживают автоматическую сериализацию
4. **Интеграция**: Требует ручной настройки ссылок на другие системы

## Планы развития

- [ ] Автоматическая сериализация компонентов
- [ ] Оптимизация производительности для больших сеток
- [ ] Визуальный редактор объектов
- [ ] Система шаблонов строительства
- [ ] Интеграция с системой ресурсов
- [ ] Поддержка сетевой игры 