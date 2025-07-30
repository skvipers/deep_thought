extends ConsoleCommand

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