# Система логирования Deep Thought

## Обзор

Новая модульная система логирования позволяет включать/отключать логи по модулям и уровням важности для ускорения загрузки проекта.

## Модули логирования

- **GENERATION** - Генерация мира, чанков, биомов
- **CHUNK** - Рендеринг чанков, создание мешей
- **OVERLAY** - Система оверлеев
- **BIOME** - Генерация и назначение биомов
- **PLANET** - Планеты и гексагональная геометрия
- **PAWN** - Пешки/юниты и их компоненты
- **EDITOR** - Редактор чанков
- **TEST** - Тесты и отладка
- **SYSTEM** - Системные сообщения
- **DEFAULT** - По умолчанию (для обратной совместимости)

## Уровни логирования

- **DEBUG** - Детальная отладочная информация
- **INFO** - Общая информация о процессе
- **WARN** - Предупреждения
- **ERROR** - Ошибки

## Использование

### Базовое логирование

```gdscript
# Новый API (рекомендуется)
Logger.info("GENERATION", "Генерация чанка завершена")
Logger.debug("CHUNK", "Создан меш с %d вершинами" % vertex_count)
Logger.warn("OVERLAY", "Оверлей не найден")
Logger.error("SYSTEM", "Критическая ошибка")

# Старый API (для обратной совместимости)
Logger.info_old("TAG", "Сообщение")
Logger.debug_old("TAG", "Отладочная информация")
```

### Управление модулями

```gdscript
# Включить/отключить конкретный модуль
Logger.enable_module("GENERATION")
Logger.disable_module("TEST")

# Включить/отключить все модули
Logger.enable_all_modules()
Logger.disable_all_modules()
```

### Управление уровнями

```gdscript
# Установить минимальный уровень логирования
Logger.set_level(Logger.LogLevel.WARN)  # Только WARN и ERROR

# Включить/отключить логирование глобально
Logger.enable_logging()
Logger.disable_logging()
```

### Готовые настройки

```gdscript
# Режим разработки (все логи включены)
Logger.setup_for_development()

# Режим релиза (только WARN и ERROR)
Logger.setup_for_release()

# Режим производительности (только ERROR)
Logger.setup_for_performance()

# Отладка конкретного модуля
LoggingConfig.debug_generation_only()
LoggingConfig.debug_chunks_only()
LoggingConfig.debug_overlays_only()
```

## Автоматическая настройка

Система автоматически настраивается при запуске проекта:

- **Debug режим** - все логи включены
- **Release режим** - только WARN и ERROR
- **Performance режим** - только ERROR

## Рекомендации по производительности

1. **Для разработки**: используйте `Logger.setup_for_development()`
2. **Для тестирования**: отключите ненужные модули
3. **Для релиза**: используйте `Logger.setup_for_release()`
4. **Для максимальной производительности**: используйте `Logger.setup_for_performance()`

## Миграция с старой системы

Старый API продолжает работать, но рекомендуется перейти на новый:

```gdscript
# Старый код
Logger.info("TAG", "Сообщение")

# Новый код
Logger.info("MODULE", "Сообщение")
```

## Примеры использования

### Отладка генерации мира
```gdscript
LoggingConfig.debug_generation_only()
```

### Отладка рендеринга чанков
```gdscript
LoggingConfig.debug_chunks_only()
```

### Отключение всех логов кроме ошибок
```gdscript
Logger.setup_for_performance()
``` 
