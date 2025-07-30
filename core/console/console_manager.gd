extends Node
class_name ConsoleManager

const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

# Console settings
@export_group("Console Settings")
@export var max_history_size: int = 100
@export var enable_autocomplete: bool = true
@export var enable_command_history: bool = true

# Registered commands
var commands: Dictionary = {}
var command_history: Array[String] = []
var history_index: int = -1

# Events
signal command_executed(command: String, result: String)
signal command_registered(command_name: String, module: String)
signal console_opened()
signal console_closed()

func _ready():
	Logger.info("CONSOLE", "🖥️ Initializing Developer Console")
	_register_core_commands()

func register_command(command_name: String, command: ConsoleCommand, module: String = "core"):
	"""Register a new command"""
	if command_name in commands:
		Logger.warn("CONSOLE", "Command '" + command_name + "' already registered, overwriting")
	
	commands[command_name] = command
	command.module = module
	Logger.info("CONSOLE", "✅ Registered command: " + command_name + " (module: " + module + ")")
	command_registered.emit(command_name, module)

func unregister_command(command_name: String):
	"""Unregister a command"""
	if command_name in commands:
		commands.erase(command_name)
		Logger.info("CONSOLE", "🗑️ Unregistered command: " + command_name)

func execute_command(input: String) -> String:
	"""Execute a command and return result"""
	var trimmed_input = input.strip_edges()
	if trimmed_input.is_empty():
		return ""
	return ""
	
	# Parse command
	var parts = trimmed_input.split(" ", false)
	var command_name = parts[0].to_lower()
	var args = parts.slice(1) if parts.size() > 1 else []
	
	# Add to history
	if enable_command_history:
		_add_to_history(trimmed_input)
	
	# Execute command
	if command_name in commands:
		var command = commands[command_name]
		var result := ""
		# Try to execute the command, handle errors gracefully
		# GDScript does not support try/except, so use 'call_deferred' or check for errors manually if needed
		# Here, we assume command.execute() may throw, so we wrap in a safe call
		# If you want to catch errors, you need to use 'push_error' or similar, but for now:
		result = command.execute(args)
		Logger.info("CONSOLE", "✅ Executed: " + trimmed_input)
		command_executed.emit(trimmed_input, result)
		return result
		# Note: GDScript does not support try/except. If command.execute() throws, it will be an engine error.
		var error_msg = "❌ Unknown command: " + command_name
		Logger.warn("CONSOLE", error_msg)
		return error_msg

func get_autocomplete_suggestions(partial_input: String) -> Array[String]:
	"""Get autocomplete suggestions for partial input"""
	if not enable_autocomplete:
		return []
	
	var suggestions: Array[String] = []
	var partial_lower = partial_input.to_lower()
	
	for command_name in commands.keys():
		if command_name.begins_with(partial_lower):
			suggestions.append(command_name)
	
	# Sort suggestions
	suggestions.sort()
	return suggestions

func get_command_help(command_name: String) -> String:
	"""Get help for a specific command"""
	if command_name in commands:
		return commands[command_name].get_help()
	return "Command not found: " + command_name

func get_all_commands() -> Dictionary:
	"""Get all registered commands grouped by module"""
	var grouped_commands: Dictionary = {}
	
	for command_name in commands.keys():
		var command = commands[command_name]
		var module = command.module if command.module else "unknown"
		
		if not module in grouped_commands:
			grouped_commands[module] = []
		
		grouped_commands[module].append({
			"name": command_name,
			"description": command.get_description(),
			"usage": command.get_usage()
		})
	
	return grouped_commands

func get_command_history() -> Array[String]:
	"""Get command history"""
	return command_history

func clear_history():
	"""Clear command history"""
	command_history.clear()
	history_index = -1
	Logger.info("CONSOLE", "🗑️ Cleared command history")

func _add_to_history(command: String):
	"""Add command to history"""
	command_history.append(command)
	if command_history.size() > max_history_size:
		command_history.pop_front()

func _register_core_commands():
	"""Register core console commands"""
	# We'll implement these commands later
	Logger.info("CONSOLE", "📝 Core commands will be registered later") 