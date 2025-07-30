# Default Job Types

Демонстрационный класс для инициализации стандартных типов работ в системе приоритетов.

## Описание

`DefaultJobTypes` - это опциональный класс, который предоставляет готовые типы работ для демонстрации и тестирования системы приоритетов. Основной класс `PrioritySystem` остается чистым и не содержит предустановленных типов работ.

## Использование

### Инициализация стандартных типов работ

```gdscript
# Инициализировать все стандартные типы работ
DefaultJobTypes.initialize_default_job_types()
```

### Очистка стандартных типов работ

```gdscript
# Удалить все стандартные типы работ
DefaultJobTypes.clear_default_job_types()
```

### Получение списка ID стандартных типов работ

```gdscript
# Получить массив ID стандартных типов работ
var default_job_ids = DefaultJobTypes.get_default_job_type_ids()
```

## Стандартные типы работ

| ID | Название | Приоритет | Описание |
|----|----------|-----------|----------|
| `doctor` | Medical | 5 (max) | Медицинское лечение и исцеление |
| `construction` | Construction | 4 | Строительные работы |
| `mining` | Mining | 4 | Добыча ресурсов |
| `cooking` | Cooking | 4 | Приготовление пищи |
| `hauling` | Hauling | 3 | Транспортировка предметов |
| `cleaning` | Cleaning | 3 | Уборка и обслуживание |
| `farming` | Farming | 3 | Выращивание культур |
| `research` | Research | 2 | Исследования и разработка |
| `crafting` | Crafting | 3 | Создание предметов |
| `guard` | Security | 5 (max) | Охрана и безопасность |

## Рекомендации

1. **Используйте только для демонстрации** - в реальных проектах создавайте собственные типы работ
2. **Очищайте после тестирования** - используйте `clear_default_job_types()` после демонстрации
3. **Настройте приоритеты** - адаптируйте приоритеты под вашу игру
4. **Добавьте описания** - используйте более детальные описания для ваших типов работ

## Пример интеграции

```gdscript
# В начале игры для демонстрации
func _ready():
    # Инициализировать стандартные типы работ
    DefaultJobTypes.initialize_default_job_types()
    
    # Настроить систему приоритетов
    PrioritySystem.set_priority_scale(1, 5, 3)
    
    # Создать менеджер приоритетов
    var priority_manager = PriorityManager.new()
    add_child(priority_manager)

# При переходе к продакшену
func setup_production_job_types():
    # Очистить демо типы
    DefaultJobTypes.clear_default_job_types()
    
    # Зарегистрировать собственные типы работ
    PrioritySystem.register_job_type("woodcutting", "Woodcutting", 3, "Cutting trees")
    PrioritySystem.register_job_type("hunting", "Hunting", 4, "Hunting animals")
    # ... другие типы работ
``` 