# 🖥️ Система консоли разработчика

## 🎯 **Обзор**

Система консоли разработчика предоставляет удобный интерфейс для выполнения команд и тестирования функциональности игры. Вместо хардкодинга клавиш для каждого теста, вы можете использовать команды консоли.

## 📁 **Структура:**

```
addons/deep_thought/core/console/
├── console_manager.gd (основной менеджер)
├── console_command.gd (базовый класс команд)
├── developer_console.gd (UI консоль)
└── commands/ (папка с командами)
    ├── core_commands.gd (базовые команды)
    ├── pawn_commands.gd (команды пешек)
    ├── world_commands.gd (команды мира)
    └── overlay_commands.gd (команды оверлеев)
```

## 🚀 **Быстрый старт:**

### **1. Добавление консоли в сцену:**
```gdscript
# В основной сцене
@export var developer_console: DeveloperConsole

func _ready():
	# Консоль автоматически инициализируется
	pass
```

### **2. Открытие консоли:**
- Нажмите `F1` (по умолчанию) для открытия/закрытия
- Нажмите `Esc` для закрытия консоли

### **3. Базовые команды:**
```
help - Показать доступные команды
clear - Очистить вывод консоли
list - Список всех команд
echo <text> - Вывести текст
camera [on/off/toggle] - Управление камерой
```

## 🔧 **Регистрация команд:**

### **Из модуля:**
```gdscript
# В любом модуле
func _ready():
	var console = get_node("/root/DeveloperConsole")
	console.register_command("spawn_pawn", _cmd_spawn_pawn)

func _cmd_spawn_pawn(args: Array) -> String:
	var count = 1
	if args.size() > 0:
		count = int(args[0])
	
	# Логика спауна пешек
	spawn_manager.spawn_pawns(count)
	return "Spawned " + str(count) + " pawns"
```

### **Команды для пешек:**
```gdscript
# Регистрация команд пешек
console.register_command("pawn_spawn", _cmd_pawn_spawn)
console.register_command("pawn_clear", _cmd_pawn_clear)
console.register_command("pawn_info", _cmd_pawn_info)

func _cmd_pawn_spawn(args: Array) -> String:
	var count = 1
	if args.size() > 0:
		count = int(args[0])
	spawn_manager.spawn_pawns(count)
	return "✅ Spawned " + str(count) + " pawns"

func _cmd_pawn_clear(args: Array) -> String:
	spawn_manager.clear_spawned_pawns()
	return "🗑️ Cleared all pawns"

func _cmd_pawn_info(args: Array) -> String:
	var info = spawn_manager.get_spawn_info()
	return "📊 Pawns: " + str(info.spawned_count) + "/" + str(info.max_spawned)
```

### **Команды для мира:**
```gdscript
# Регистрация команд мира
console.register_command("world_rebuild", _cmd_world_rebuild)
console.register_command("world_info", _cmd_world_info)

func _cmd_world_rebuild(args: Array) -> String:
	world_preview.rebuild_chunks()
	return "🌍 World rebuilt"

func _cmd_world_info(args: Array) -> String:
	return "World info: " + str(world_preview.get_chunk_count()) + " chunks"
```

## 🎮 **Использование:**

### **Открытие консоли:**
1. Нажмите `F1` во время игры
2. Введите команду и нажмите `Enter`
3. Результат появится в консоли

### **Автодополнение:**
- Начните вводить команду
- Появится список доступных команд
- Выберите нужную команду

### **История команд:**
- Используйте стрелки вверх/вниз для навигации по истории
- Команды сохраняются автоматически

## 📋 **Примеры команд:**

### **Тестирование пешек:**
```
pawn_spawn 5     # Спаун 5 пешек
pawn_clear       # Очистить всех пешек
pawn_info        # Информация о пешках
```

### **Тестирование мира:**
```
world_rebuild    # Перестроить мир
world_info       # Информация о мире
```

### **Управление камерой:**
```
camera on        # Включить управление камерой
camera off       # Выключить управление камерой
camera toggle    # Переключить состояние камеры
```

### **Отладка:**
```
echo Hello World # Вывести текст
clear           # Очистить консоль
help            # Справка
```

## 🔧 **Настройка:**

### **Изменение клавиши открытия:**
```gdscript
developer_console.toggle_key = KEY_F2  # Изменить на F2
```

### **Отключение автодополнения:**
```gdscript
developer_console.enable_autocomplete = false
```

### **Изменение размера истории:**
```gdscript
developer_console.max_output_lines = 200
```

## 🎯 **Преимущества:**

### **1. Удобство:**
- Не нужно помнить клавиши для каждого теста
- Единый интерфейс для всех команд
- Автодополнение и история

### **2. Модульность:**
- Каждый модуль может регистрировать свои команды
- Легко добавлять новые команды
- Изолированность команд

### **3. Отладка:**
- Быстрый доступ к функциям
- Просмотр результатов команд
- Логирование выполнения

### **4. Расширяемость:**
- Простая регистрация новых команд
- Группировка по модулям
- Кастомные параметры команд

### **5. Управление камерой:**
- Включение/выключение управления камерой
- Удобно при работе с UI
- Быстрое переключение режимов

## 🚀 **Готово к использованию!**

Система консоли разработчика готова к интеграции в игру. Просто добавьте `DeveloperConsole` в основную сцену и начните регистрировать команды! 🎮 