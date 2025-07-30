extends RefCounted

const ConsoleCommand = preload("res://addons/deep_thought/core/console/console_command.gd")

# === Core Console Commands ===

class ConsoleHelpCommand extends ConsoleCommand:
	func _init():
		super._init("help", "Show help for commands")
	
	func execute(args: Array[String]) -> String:
		if args.is_empty():
			return "Usage: help [command_name]\nShows help for available commands"
		
		var command_name = args[0]
		# Note: This will need to be handled by the console manager
		return "Help for: " + command_name
	
	func get_usage() -> String:
		return "help [command_name]"

class ConsoleClearCommand extends ConsoleCommand:
	func _init():
		super._init("clear", "Clear console output")
	
	func execute(args: Array[String]) -> String:
		# This will be handled by the UI
		return "Console cleared"
	
	func get_usage() -> String:
		return "clear"

class ConsoleListCommand extends ConsoleCommand:
	func _init():
		super._init("list", "List all available commands")
	
	func execute(args: Array[String]) -> String:
		# Note: This will need to be handled by the console manager
		return "📋 Available commands:\nUse 'help' to see all commands"
	
	func get_usage() -> String:
		return "list"

class ConsoleHistoryCommand extends ConsoleCommand:
	func _init():
		super._init("history", "Show command history")
	
	func execute(args: Array[String]) -> String:
		# Note: This will need to be handled by the console manager
		return "📜 Command history:\nUse console manager to access history"
	
	func get_usage() -> String:
		return "history" 