extends Node
class_name Logger

enum LogLevel { DEBUG, INFO, WARN, ERROR }

# Модули логирования - можно включать/отключать по модулям
static var enabled_modules := {
	"GENERATION": true,      # Генерация мира
	"CHUNK": true,           # Чанки и рендеринг
	"OVERLAY": true,         # Оверлеи
	"BIOME": true,           # Биомы
	"PLANET": true,          # Планеты
	"PAWN": true,            # Пешки/юниты
	"EDITOR": true,          # Редактор
	"TEST": true,            # Тесты
	"SYSTEM": true,          # Системные сообщения
	"DEFAULT": true          # По умолчанию
}

static var output_file_path := ""
static var log_to_file := false
static var current_level := LogLevel.INFO  # По умолчанию INFO для ускорения
static var logging_enabled := true          # Глобальное отключение логирования

# Быстрые проверки для отключения логирования
static func is_module_enabled(module: String) -> bool:
	return logging_enabled and enabled_modules.has(module) and enabled_modules[module]

static func is_level_enabled(level: LogLevel) -> bool:
	return logging_enabled and level >= current_level

# Основные методы логирования с проверкой модулей
static func info(module: String, message: String) -> void:
	if is_module_enabled(module) and is_level_enabled(LogLevel.INFO):
		_log(LogLevel.INFO, module, message)

static func warn(module: String, message: String) -> void:
	if is_module_enabled(module) and is_level_enabled(LogLevel.WARN):
		_log(LogLevel.WARN, module, message)

static func error(module: String, message: String) -> void:
	if is_module_enabled(module) and is_level_enabled(LogLevel.ERROR):
		_log(LogLevel.ERROR, module, message)

static func debug(module: String, message: String) -> void:
	if is_module_enabled(module) and is_level_enabled(LogLevel.DEBUG):
		_log(LogLevel.DEBUG, module, message)

# Методы для обратной совместимости (старый API)
static func info_old(tag: String, message: String) -> void:
	info("DEFAULT", "[%s] %s" % [tag, message])

static func warn_old(tag: String, message: String) -> void:
	warn("DEFAULT", "[%s] %s" % [tag, message])

static func error_old(tag: String, message: String) -> void:
	error("DEFAULT", "[%s] %s" % [tag, message])

static func debug_old(tag: String, message: String) -> void:
	debug("DEFAULT", "[%s] %s" % [tag, message])

# Управление модулями
static func enable_module(module: String) -> void:
	enabled_modules[module] = true

static func disable_module(module: String) -> void:
	enabled_modules[module] = false

static func enable_all_modules() -> void:
	for module in enabled_modules:
		enabled_modules[module] = true

static func disable_all_modules() -> void:
	for module in enabled_modules:
		enabled_modules[module] = false

# Управление уровнями
static func set_level(level: LogLevel) -> void:
	current_level = level

static func enable_logging() -> void:
	logging_enabled = true

static func disable_logging() -> void:
	logging_enabled = false

# Настройки для разных режимов
static func setup_for_development() -> void:
	logging_enabled = true
	current_level = LogLevel.DEBUG
	enable_all_modules()

static func setup_for_release() -> void:
	logging_enabled = true
	current_level = LogLevel.WARN  # Только предупреждения и ошибки
	disable_module("DEBUG")
	disable_module("TEST")

static func setup_for_performance() -> void:
	logging_enabled = true
	current_level = LogLevel.ERROR  # Только ошибки
	disable_all_modules()
	enable_module("SYSTEM")

static func set_output_file(path: String) -> void:
	output_file_path = path
	log_to_file = true

static func _log(level: LogLevel, module: String, message: String) -> void:
	var timestamp = Time.get_datetime_string_from_system(true)
	var level_name = ["DEBUG", "INFO", "WARN", "ERROR"][level]
	var line = "[%s] [%s] [%s] %s" % [timestamp, level_name, module, message]

	match level:
		LogLevel.ERROR: push_error(line)
		LogLevel.WARN: push_warning(line)
		_: print(line)

	if log_to_file and output_file_path != "":
		var file := FileAccess.open(output_file_path, FileAccess.WRITE_READ)
		if file:
			file.seek_end()
			file.store_line(line)
			file.close()
