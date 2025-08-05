# Строительная система Deep Thought

## Обзор

Строительная система предоставляет полный фреймворк для создания, размещения и управления строительными объектами в игровом мире.

## Основные компоненты

### BuildObject
Базовый класс для всех строительных объектов.

**Основные свойства:**
- `origin: Vector3i` - якорная точка объекта
- `size: Vector3i` - размер в блоках
- `relative_cells: Array[Vector3i]` - список смещений от origin
- `rotation: int` - поворот объекта
- `object_id: String` - уникальный идентификатор
- `display_name: String` - название для отображения
- `mesh: Mesh` - 3D модель объекта
- `icon: Texture2D` - иконка для UI
- `is_interactable: bool` - можно ли взаимодействовать
- `priority: int` - приоритет объекта
- `tags: Array[String]` - теги для категоризации
- `build_cost: Dictionary` - стоимость строительства
- `build_time: float` - время строительства
- `build_progress: float` - прогресс строительства (0.0 - 1.0)
- `is_built: bool` - завершено ли строительство

**Основные методы:**
- `get_occupied_positions() -> Array[Vector3i]` - возвращает все занимаемые позиции
- `occupies_position(pos: Vector3i) -> bool` - проверяет, занимает ли объект позицию
- `set_position(new_origin: Vector3i)` - устанавливает позицию
- `get_rotated_size() -> Vector3i` - возвращает размер с учетом поворота
- `clone() -> BuildObject` - клонирует объект
- `init_from_data(data: BuildObjectData)` - инициализация из данных
- `update_build_progress(delta: float)` - обновляет прогресс строительства

### InteractableObject
Наследуется от BuildObject, добавляет поддержку взаимодействия и логических компонентов.

**Дополнительные свойства:**
- `logic_components: Array[LogicComponent]` - логические компоненты
- `interaction_range: float` - диапазон взаимодействия
- `can_interact: bool` - можно ли взаимодействовать
- `allowed_actors: Array` - список разрешенных акторов

**Дополнительные методы:**
- `interact(actor)` - взаимодействие с объектом
- `update(delta: float)` - обновление объекта каждый тик
- `add_logic_component(component: LogicComponent)` - добавление компонента
- `remove_logic_component(component: LogicComponent)` - удаление компонента
- `get_logic_component(component_name: String) -> LogicComponent` - получение компонента
- `can_actor_interact(actor) -> bool` - проверка возможности взаимодействия

### LogicComponent
Базовый модуль поведения для интерактивных объектов.

**Основные свойства:**
- `priority: int` - приоритет компонента
- `is_enabled: bool` - активен ли компонент
- `component_name: String` - название компонента
- `parent_object: InteractableObject` - ссылка на родительский объект

**Основные методы:**
- `on_init()` - инициализация компонента
- `on_tick(delta: float)` - обновление каждый тик
- `on_interact(actor)` - взаимодействие
- `enable()` - активация компонента
- `disable()` - деактивация компонента
- `set_parent(object: InteractableObject)` - установка родителя

### BuildObjectData
Ресурс, описывающий объект, который можно построить.

**Основные свойства:**
- `id: String` - уникальный идентификатор
- `name: String` - название
- `mesh: Mesh` - 3D модель
- `size: Vector3i` - размер
- `icon: Texture2D` - иконка
- `is_interactable: bool` - интерактивность
- `logic_components: Array[PackedScene]` - логические компоненты
- `priority: int` - приоритет
- `tags: Array[String]` - теги
- `build_cost: Dictionary` - стоимость
- `build_time: float` - время строительства
- `category: String` - категория
- `description: String` - описание

**Основные методы:**
- `create_build_object() -> BuildObject` - создание объекта из данных

### BuildGrid
Компонент для управления размещением строительных объектов.

**Основные свойства:**
- `main_grid: Dictionary` - основная сетка (Dictionary<Vector3i, BuildCell>)
- `grid_size: Vector3i` - размер сетки

**Основные методы:**
- `place_object(pos: Vector3i, object: BuildObject) -> bool` - размещение объекта
- `erase_object(pos: Vector3i) -> bool` - удаление объекта
- `get_object(pos: Vector3i) -> BuildObject` - получение объекта
- `has_object_at(pos: Vector3i) -> bool` - проверка наличия объекта
- `is_position_free(pos: Vector3i) -> bool` - проверка свободы позиции
- `can_place_object(pos: Vector3i, size: Vector3i) -> bool` - проверка возможности размещения
- `clear_grid()` - очистка сетки
- `get_all_objects() -> Array[BuildObject]` - все объекты
- `get_objects_in_range(min_pos: Vector3i, max_pos: Vector3i) -> Array[BuildObject]` - объекты в диапазоне

**Сигналы:**
- `object_placed(pos: Vector3i, object: BuildObject)` - объект размещен
- `object_removed(pos: Vector3i, object: BuildObject)` - объект удален
- `grid_cleared` - сетка очищена

### BuildCell
Ячейка сетки строительства.

**Основные свойства:**
- `subdivisions: int` - уровень вложенности (1, 2, 4)
- `subgrid: Dictionary` - подсетка (Dictionary[Vector3i, BuildObject])
- `main_object: BuildObject` - основной объект

**Основные методы:**
- `is_empty() -> bool` - проверка пустоты
- `place_object(object: BuildObject, sub_position: Vector3i)` - размещение объекта
- `remove_object(sub_position: Vector3i)` - удаление объекта
- `get_object(sub_position: Vector3i) -> BuildObject` - получение объекта
- `has_object_at(sub_position: Vector3i) -> bool` - проверка наличия объекта
- `get_all_objects() -> Array[BuildObject]` - все объекты в ячейке

### BuildObjectFactory
Фабрика для создания строительных объектов.

**Основные методы:**
- `initialize()` - инициализация фабрики
- `get_build_object_data(id: String) -> BuildObjectData` - получение данных по ID
- `create_build_object(id: String) -> BuildObject` - создание объекта по ID
- `get_all_object_ids() -> Array[String]` - все доступные ID
- `get_all_build_objects_data() -> Array[BuildObjectData]` - все данные объектов
- `get_objects_by_category(category: String) -> Array[BuildObjectData]` - объекты по категории
- `get_objects_by_tag(tag: String) -> Array[BuildObjectData]` - объекты по тегу
- `has_build_object(id: String) -> bool` - проверка существования объекта
- `reload()` - перезагрузка данных

### OccupancyManager
Менеджер для проверки возможности размещения объектов.

**Маски проверки:**
- `TERRAIN_ONLY` - только проверка рельефа
- `STRUCTURE_ONLY` - только проверка структур
- `DEFAULT` - полная проверка
- `ALLOW_CEILING` - разрешить размещение под потолком
- `IGNORE_STRUCTURES` - игнорировать существующие структуры
- `IGNORE_TERRAIN` - игнорировать рельеф

**Основные методы:**
- `initialize(terrain: Object, build: Object)` - инициализация
- `is_space_free(pos: Vector3i, size: Vector3i, mask: CheckMask) -> bool` - проверка свободы места
- `can_place_with_neighbors(pos: Vector3i, size: Vector3i, required_neighbors: Array[String]) -> bool` - проверка с соседями
- `has_sufficient_space(pos: Vector3i, size: Vector3i, margin: int) -> bool` - проверка достаточного места

## Использование

### Создание объекта

```gdscript
# Создание через фабрику
var factory = BuildObjectFactory.new()
factory.initialize()

var house_data = factory.get_build_object_data("house")
var house = house_data.create_build_object()

# Или напрямую
var house = BuildObject.new()
house.init_from_data(house_data)
```

### Размещение объекта

```gdscript
var build_grid = BuildGrid.new()
build_grid.set_grid_size(Vector3i(100, 10, 100))

var success = build_grid.place_object(Vector3i(10, 0, 10), house)
if success:
    print("Дом размещен успешно")
```

### Проверка возможности размещения

```gdscript
var occupancy_manager = OccupancyManager.new()
occupancy_manager.initialize(terrain_grid, build_grid)

var can_place = occupancy_manager.is_space_free(
    Vector3i(10, 0, 10), 
    Vector3i(3, 2, 3),
    OccupancyManager.CheckMask.DEFAULT
)
```

### Создание интерактивного объекта

```gdscript
var farm = InteractableObject.new()
farm.init_from_data(farm_data)

# Добавление логического компонента
var production_component = ProductionComponent.new()
production_component.production_type = "food"
production_component.production_rate = 2.0
farm.add_logic_component(production_component)

# Взаимодействие
farm.interact(player)
```

### Обновление объектов

```gdscript
func _process(delta):
    for object in build_grid.get_all_objects():
        if object is InteractableObject:
            object.update(delta)
```

## Создание собственных компонентов

```gdscript
class_name CustomComponent
extends LogicComponent

@export var custom_property: String = ""

func on_init():
    component_name = "custom"
    print("Custom component initialized")

func on_tick(delta: float):
    if is_enabled:
        # Ваша логика здесь
        pass

func on_interact(actor):
    if is_enabled:
        # Логика взаимодействия
        pass
```

## Структура файлов

```
addons/deep_thought/
├── core/build/
│   ├── build_object.gd
│   ├── interactable_object.gd
│   ├── logic_component.gd
│   ├── build_cell.gd
│   ├── build_grid.gd
│   ├── build_object_data.gd
│   ├── build_object_factory.gd
│   └── components/
│       └── production_component.gd
├── managers/
│   └── occupancy_manager.gd
└── data/build_objects/
    ├── house.tres
    └── farm.tres
```

## Интеграция с системой приоритетов

Строительная система интегрируется с существующей системой приоритетов Deep Thought:

- Объекты имеют приоритет (`priority`)
- Логические компоненты поддерживают приоритеты
- Можно использовать `PriorityComponent` для сложной логики приоритетов

## Интеграция с системой времени

Объекты и компоненты поддерживают систему тиков:

- `on_tick(delta: float)` вызывается каждый тик
- Поддержка `Tickable` интерфейса
- Интеграция с `TickManager` 