extends Control
class_name DeveloperConsole

const Logger = preload("res://addons/deep_thought/utils/logger/logger.gd")

# Console UI
@export_group("Console UI")
@export var console_panel: PanelContainer
@export var input_field: LineEdit
@export var output_text: RichTextLabel
@export var suggestions_list: ItemList
@export var status_label: Label
@export var close_button: Button
@export var history_button: Button
@export var clear_button: Button

# Console settings
@export_group("Console Settings")
@export var toggle_key: Key = KEY_F1
@export var max_output_lines: int = 100
@export var enable_autocomplete: bool = true

# Commands
var commands: Dictionary = {}
var command_history: Array[String] = []
var history_index: int = -1

# Console state
var is_console_open: bool = false

func _ready():
	Logger.info("CONSOLE", "🖥️ Initializing Developer Console UI")
	_setup_console()
	_register_basic_commands()

func _input(event):
	if event.is_action_pressed("ui_cancel") and is_console_open:
		close_console()
		get_viewport().set_input_as_handled()
	
	if event is InputEventKey and event.is_pressed() and event.keycode == toggle_key:
		toggle_console()
		get_viewport().set_input_as_handled()

func toggle_console():
	if is_console_open:
		close_console()
	else:
		open_console()

func open_console():
	is_console_open = true
	console_panel.visible = true
	input_field.grab_focus()
	_update_status("Ready")
	Logger.info("CONSOLE", "📖 Console opened")

func close_console():
	is_console_open = false
	console_panel.visible = false
	input_field.release_focus()
	_update_status("Closed")
	Logger.info("CONSOLE", "📕 Console closed")

func _setup_console():
	"""Setup console UI"""
	if console_panel:
		console_panel.visible = false
	
	if input_field:
		input_field.text_submitted.connect(_on_command_submitted)
		input_field.text_changed.connect(_on_input_changed)
	
	if output_text:
		output_text.text = "🖥️ Developer Console Ready\nType 'help' for available commands\n"
	
	if close_button:
		close_button.pressed.connect(close_console)
	
	if history_button:
		history_button.pressed.connect(_show_history)
	
	if clear_button:
		clear_button.pressed.connect(_clear_output)

func _on_command_submitted(command: String):
	"""Handle command submission"""
	if command.strip_edges().is_empty():
		return
	
	# Add to history
	command_history.append(command)
	if command_history.size() > 50:
		command_history.pop_front()
	
	# Execute command
	var result = execute_command(command)
	
	# Display result
	_append_output("> " + command)
	if result:
		_append_output(result)
	
	# Clear input
	input_field.text = ""
	_update_status("Command executed")

func _on_input_changed(new_text: String):
	"""Handle input changes for autocomplete"""
	if not enable_autocomplete or not suggestions_list:
		return
	
	var suggestions = _get_suggestions(new_text)
	_update_suggestions(suggestions)

func execute_command(input: String) -> String:
	"""Execute a command and return result"""
	var parts = input.split(" ", false)
	var command_name = parts[0].to_lower()
	var args = parts.slice(1) if parts.size() > 1 else []
	
	if command_name in commands:
		return commands[command_name].call(args)
	else:
		return "❌ Unknown command: " + command_name

func _get_suggestions(partial: String) -> Array[String]:
	"""Get command suggestions"""
	var suggestions: Array[String] = []
	var partial_lower = partial.to_lower()
	
	for command_name in commands.keys():
		if command_name.begins_with(partial_lower):
			suggestions.append(command_name)
	
	return suggestions

func _update_suggestions(suggestions: Array[String]):
	"""Update suggestions list"""
	if not suggestions_list:
		return
	
	suggestions_list.clear()
	for suggestion in suggestions:
		suggestions_list.add_item(suggestion)

func _append_output(text: String):
	"""Append text to console output"""
	if not output_text:
		return
	
	output_text.append_text(text + "\n")
	
	# Limit output lines
	var lines = output_text.text.split("\n")
	if lines.size() > max_output_lines:
		output_text.text = "\n".join(lines.slice(-max_output_lines))

func _update_status(status: String):
	"""Update status label"""
	if status_label:
		status_label.text = status

func _show_history():
	"""Show command history"""
	if command_history.is_empty():
		_append_output("📜 No command history")
		return
	
	_append_output("📜 Command history:")
	for i in range(command_history.size()):
		_append_output(str(i + 1) + ". " + command_history[i])

func _clear_output():
	"""Clear console output"""
	if output_text:
		output_text.text = ""
	_append_output("Console cleared")

func register_command(name: String, callback: Callable):
	"""Register a new command"""
	commands[name] = callback
	Logger.info("CONSOLE", "✅ Registered command: " + name)

func _cmd_help(args: Array) -> String:
	"""Help command"""
	if args.is_empty():
		return "Available commands: help, clear, list, echo\nUse 'help <command>' for detailed help"
	
	var command = args[0]
	if command in commands:
		return "Help for '" + command + "': Use the command to see what it does"
	else:
		return "Unknown command: " + command

func _cmd_clear(args: Array) -> String:
	"""Clear console output"""
	if output_text:
		output_text.text = ""
	return "Console cleared"

func _cmd_list(args: Array) -> String:
	"""List all commands"""
	var result = "📋 Available commands:\n"
	for command_name in commands.keys():
		result += "  " + command_name + "\n"
	return result

func _cmd_echo(args: Array) -> String:
	"""Echo command - prints arguments"""
	return " ".join(args)

func _cmd_camera(args: Array) -> String:
	"""Camera control command"""
	if args.is_empty():
		return "Usage: camera [on/off/toggle]\nControls camera input"
	
	var action = args[0].to_lower()
	var camera = _find_camera()
	
	if not camera:
		return "❌ Camera not found"
	
	var can_control := false
	if _has_property(camera, "input_enabled"):
		can_control = true
	elif camera.has_method("set_input_enabled"):
		can_control = true
	
	if not can_control:
		return "❌ Camera does not support input control"
	
	var enabled: bool
	match action:
		"on":
			enabled = true
		"off":
			enabled = false
		"toggle":
			if _has_property(camera, "input_enabled"):
				enabled = not camera.input_enabled
			elif camera.has_method("is_input_enabled"):
				enabled = not camera.is_input_enabled()
			else:
				return "❌ Camera does not support input control"
		_:
			return "❌ Invalid action. Use: on, off, toggle"
	
	if _has_property(camera, "input_enabled"):
		camera.input_enabled = enabled
	elif camera.has_method("set_input_enabled"):
		camera.set_input_enabled(enabled)
	else:
		return "❌ Camera does not support input control"
	
	return "📷 Camera input " + ("enabled" if enabled else "disabled")

func _has_property(obj, prop: String) -> bool:
	"""Check if object has property"""
	for p in obj.get_property_list():
		if p.name == prop:
			return true
	return false

func _find_camera():
	"""Find camera in scene (рекурсивно)"""
	var root = Engine.get_main_loop().get_root()
	return _find_camera_recursive(root)

func _find_camera_recursive(node):
	if node is Camera3D:
		return node
	if node.has_method("input_enabled"):
		return node
	for child in node.get_children():
		var found = _find_camera_recursive(child)
		if found:
			return found
	return null

func _register_basic_commands():
	"""Register basic console commands"""
	register_command("help", _cmd_help)
	register_command("clear", _cmd_clear)
	register_command("list", _cmd_list)
	register_command("echo", _cmd_echo)
	register_command("camera", _cmd_camera) 
