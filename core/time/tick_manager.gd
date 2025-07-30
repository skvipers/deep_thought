extends Node
class_name TickManager

const TickSystem = preload("res://addons/deep_thought/core/time/tick_system.gd")
const Tickable = preload("res://addons/deep_thought/core/time/tickable.gd")

## Frame counters for each tick level
var _frame_counters: Array[int] = [0, 0, 0, 0, 0]
## Tickable objects organized by tick level
var _tickables: Array[Array] = [[], [], [], [], []]
## Total weights for each tick level (for load balancing)
var _total_weights: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
## Performance tracking
var _tick_times: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var _last_tick_times: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]

## Time scale from TimeController
var time_scale: float = 1.0
## Whether to skip low-weight ticks under high load
var skip_low_weight: bool = false
## Performance threshold for skipping (ms per tick level)
var performance_threshold: float = 16.0  # 60 FPS = ~16ms

## Signals
signal tickable_registered(tickable: Tickable, level: TickSystem.TickLevel)
signal tickable_unregistered(tickable: Tickable, level: TickSystem.TickLevel)
signal tick_level_processed(level: TickSystem.TickLevel, delta: float, tick_count: int)

func _ready():
	# Initialize arrays
	for i in range(5):
		_tickables[i] = []
		_total_weights[i] = 0.0
		_tick_times[i] = 0.0
		_last_tick_times[i] = 0.0

func _process(delta: float):
	# Apply time scale
	var scaled_delta = delta * time_scale
	
	# Update frame counters
	for i in range(_frame_counters.size()):
		_frame_counters[i] += 1
	
	# Process each tick level
	_process_tick_level(TickSystem.TickLevel.IMMEDIATE, scaled_delta)
	
	if _should_tick(TickSystem.TickLevel.HIGH):
		_process_tick_level(TickSystem.TickLevel.HIGH, scaled_delta)
	
	if _should_tick(TickSystem.TickLevel.MEDIUM):
		_process_tick_level(TickSystem.TickLevel.MEDIUM, scaled_delta)
	
	if _should_tick(TickSystem.TickLevel.LOW):
		_process_tick_level(TickSystem.TickLevel.LOW, scaled_delta)
	
	if _should_tick(TickSystem.TickLevel.RARE):
		_process_tick_level(TickSystem.TickLevel.RARE, scaled_delta)

func _should_tick(level: TickSystem.TickLevel) -> bool:
	# Calculate frame interval for this level
	var frame_interval = 1 << level
	return _frame_counters[level] % frame_interval == 0

func _process_tick_level(level: TickSystem.TickLevel, delta: float):
	var start_time = Time.get_ticks_msec()
	var level_index = level
	var tickables = _tickables[level_index]
	var processed_count = 0
	
	# Check if we should skip low-weight ticks
	var should_skip_low = skip_low_weight and _last_tick_times[level_index] > performance_threshold
	
	for tickable in tickables:
		if not is_instance_valid(tickable) or not tickable.tick_active:
			continue
		
		# Skip low-weight ticks if performance is poor
		if should_skip_low and tickable.tick_weight < 0.5:
			continue
		
		tickable._tick(delta)
		processed_count += 1
	
	# Update performance tracking
	_last_tick_times[level_index] = Time.get_ticks_msec() - start_time
	_tick_times[level_index] = _last_tick_times[level_index]
	
	emit_signal("tick_level_processed", level, delta, processed_count)

## Register a tickable object
func register_tickable(tickable: Tickable, level: TickSystem.TickLevel = TickSystem.TickLevel.MEDIUM):
	if not is_instance_valid(tickable):
		return
	
	var level_index = level
	_tickables[level_index].append(tickable)
	_total_weights[level_index] += tickable.tick_weight
	
	tickable._on_tick_registered()
	emit_signal("tickable_registered", tickable, level)

## Unregister a tickable object
func unregister_tickable(tickable: Tickable):
	if not is_instance_valid(tickable):
		return
	
	var level_index = tickable.tick_level
	var tickables = _tickables[level_index]
	
	var index = tickables.find(tickable)
	if index != -1:
		tickables.remove_at(index)
		_total_weights[level_index] -= tickable.tick_weight
		
		tickable._on_tick_unregistered()
		emit_signal("tickable_unregistered", tickable, tickable.tick_level)

## Change tick level of a tickable object
func change_tick_level(tickable: Tickable, new_level: TickSystem.TickLevel):
	if not is_instance_valid(tickable):
		return
	
	# Remove from old level
	var old_level_index = tickable.tick_level
	var old_tickables = _tickables[old_level_index]
	var index = old_tickables.find(tickable)
	if index != -1:
		old_tickables.remove_at(index)
		_total_weights[old_level_index] -= tickable.tick_weight
	
	# Add to new level
	tickable.tick_level = new_level
	var new_level_index = new_level
	_tickables[new_level_index].append(tickable)
	_total_weights[new_level_index] += tickable.tick_weight

## Get statistics for a tick level
func get_level_stats(level: TickSystem.TickLevel) -> Dictionary:
	var level_index = level
	return {
		"tickable_count": _tickables[level_index].size(),
		"total_weight": _total_weights[level_index],
		"last_tick_time": _last_tick_times[level_index],
		"average_tick_time": _tick_times[level_index]
	}

## Get all statistics
func get_all_stats() -> Dictionary:
	var stats = {}
	for level in TickSystem.TickLevel.values():
		stats[TickSystem.TickLevel.keys()[level]] = get_level_stats(level)
	return stats

## Clear all tickables
func clear_all():
	for level_index in range(_tickables.size()):
		for tickable in _tickables[level_index]:
			if is_instance_valid(tickable):
				tickable._on_tick_unregistered()
		_tickables[level_index].clear()
		_total_weights[level_index] = 0.0 