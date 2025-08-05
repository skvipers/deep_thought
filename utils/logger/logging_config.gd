extends Node
class_name LoggingConfig

const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

# Конфигурация логирования для разных режимов
static func setup_logging() -> void:
	# Определяем режим работы по переменной окружения или настройкам проекта
	var debug_mode = OS.is_debug_build()
	var performance_mode = false  # Можно добавить проверку специальной переменной
	
	if performance_mode:
		Logger.setup_for_performance()
		Logger.info("SYSTEM", "Logging: PERFORMANCE mode - only ERROR level")
	elif debug_mode:
		Logger.setup_for_development()
		Logger.info("SYSTEM", "Logging: DEVELOPMENT mode - all levels enabled")
	else:
		Logger.setup_for_release()
		Logger.info("SYSTEM", "Logging: RELEASE mode - WARN and ERROR only")

# Методы для ручного управления логированием
static func enable_generation_logs() -> void:
	Logger.enable_module("GENERATION")

static func disable_generation_logs() -> void:
	Logger.disable_module("GENERATION")

static func enable_chunk_logs() -> void:
	Logger.enable_module("CHUNK")

static func disable_chunk_logs() -> void:
	Logger.disable_module("CHUNK")

static func enable_overlay_logs() -> void:
	Logger.enable_module("OVERLAY")

static func disable_overlay_logs() -> void:
	Logger.disable_module("OVERLAY")

static func enable_pawn_logs() -> void:
	Logger.enable_module("PAWN")

static func disable_pawn_logs() -> void:
	Logger.disable_module("PAWN")

static func enable_test_logs() -> void:
	Logger.enable_module("TEST")

static func disable_test_logs() -> void:
	Logger.disable_module("TEST")

static func enable_game_logs() -> void:
	Logger.enable_module("GAME")

static func disable_game_logs() -> void:
	Logger.disable_module("GAME")

# Быстрые настройки для отладки
static func debug_generation_only() -> void:
	Logger.disable_all_modules()
	Logger.enable_module("GENERATION")
	Logger.set_level(Logger.LogLevel.DEBUG)

static func debug_chunks_only() -> void:
	Logger.disable_all_modules()
	Logger.enable_module("CHUNK")
	Logger.set_level(Logger.LogLevel.DEBUG)

static func debug_overlays_only() -> void:
	Logger.disable_all_modules()
	Logger.enable_module("OVERLAY")
	Logger.set_level(Logger.LogLevel.DEBUG)

static func debug_pawns_only() -> void:
	Logger.disable_all_modules()
	Logger.enable_module("PAWN")
	Logger.set_level(Logger.LogLevel.DEBUG) 
