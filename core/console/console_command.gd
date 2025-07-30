extends RefCounted
class_name ConsoleCommand

var name: String
var description: String
var module: String = "core"

func _init(command_name: String, command_description: String):
	name = command_name
	description = command_description

func execute(args: Array) -> String:
	"""Execute the command with given arguments"""
	push_error("ConsoleCommand.execute() not implemented")
	return "Command not implemented"

func get_help() -> String:
	"""Get detailed help for this command"""
	return description + "\nUsage: " + get_usage()

func get_description() -> String:
	"""Get short description of the command"""
	return description

func get_usage() -> String:
	"""Get usage syntax for this command"""
	return name 