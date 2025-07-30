extends RefCounted
class_name Tickable

const TickSystem = preload("res://addons/deep_thought/core/time/tick_system.gd")

## Tick frequency level for this object
var tick_level: TickSystem.TickLevel = TickSystem.TickLevel.MEDIUM
## Weight for load balancing (higher = more important)
var tick_weight: float = 1.0
## Whether this tickable is currently active
var tick_active: bool = true

## Called by TickManager during tick processing
## Override this method to implement tick logic
func _tick(delta: float) -> void:
	pass

## Called when tickable is registered with TickManager
func _on_tick_registered() -> void:
	pass

## Called when tickable is unregistered from TickManager
func _on_tick_unregistered() -> void:
	pass 