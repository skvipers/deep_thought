extends WorkTask
class_name ImmediateCommand

## Special task type that executes without pawns
## Examples: toggling logic, setting flags, etc.

const WorkTask = preload("res://addons/deep_thought/core/priority/work_task.gd")

## Callback function to execute
var callback_function: Callable
## Callback parameters
var callback_parameters: Array = []
## Success flag
var execution_success: bool = false

func _init(cmd_description: String, callback: Callable, parameters: Array = []):
	super._init("immediate", 0)  # Immediate commands have no job type
	description = cmd_description
	callback_function = callback
	callback_parameters = parameters
	is_immediate = true

## Execute the immediate command
func execute_direct():
	if not is_immediate:
		fail()
		return
	
	start_execution()
	
	# Execute the callback function
	if callback_function.is_valid():
		var result
		if callback_parameters.is_empty():
			result = callback_function.call()
		else:
			result = callback_function.callv(callback_parameters)
		
		# Check if execution was successful
		if result != null and result is bool:
			execution_success = result
		else:
			execution_success = true
	else:
		execution_success = false
	
	# Complete or fail based on result
	if execution_success:
		complete()
	else:
		fail()

## Get execution success status
func was_successful() -> bool:
	return execution_success

## Set callback function
func set_callback(callback: Callable):
	callback_function = callback

## Set callback parameters
func set_parameters(parameters: Array):
	callback_parameters = parameters

## Create a simple toggle command
static func create_toggle_command(description: String, target_object, property_name: String) -> ImmediateCommand:
	var callback = func():
		if target_object.has_method("get") and target_object.has_method("set"):
			var current_value = target_object.get(property_name)
			target_object.set(property_name, not current_value)
			return true
		return false
	
	return ImmediateCommand.new(description, callback)

## Create a flag setting command
static func create_flag_command(description: String, target_object, property_name: String, value) -> ImmediateCommand:
	var callback = func():
		if target_object.has_method("set"):
			target_object.set(property_name, value)
			return true
		return false
	
	return ImmediateCommand.new(description, callback)

## Create a method call command
static func create_method_command(description: String, target_object, method_name: String, parameters: Array = []) -> ImmediateCommand:
	var callback = func():
		if target_object.has_method(method_name):
			if parameters.is_empty():
				target_object.call(method_name)
			else:
				target_object.callv(method_name, parameters)
			return true
		return false
	
	return ImmediateCommand.new(description, callback) 