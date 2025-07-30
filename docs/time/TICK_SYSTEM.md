# Tick System Documentation

## Overview

The Tick System provides a flexible, performant framework for managing simulation updates at different frequencies. It's designed for complex simulations where different systems need to update at varying rates (e.g., creature AI = HIGH frequency, weather = RARE frequency).

## Core Components

### TickSystem
Defines the tick frequency levels and provides the base interface.

**Tick Levels:**
- `IMMEDIATE` (0): Every frame (60 FPS)
- `HIGH` (1): Every 2 frames (30 FPS)
- `MEDIUM` (2): Every 4 frames (15 FPS)
- `LOW` (3): Every 8 frames (7.5 FPS)
- `RARE` (4): Every 16 frames (3.75 FPS)

### Tickable
Base interface for objects that need tick processing.

**Properties:**
- `tick_level`: TickLevel - Frequency of updates
- `tick_weight`: float - Importance for load balancing
- `tick_active`: bool - Whether this tickable is active

**Methods:**
- `_tick(delta: float)` - Override to implement tick logic
- `_on_tick_registered()` - Called when registered
- `_on_tick_unregistered()` - Called when unregistered

### TickManager
Central node that processes all tickable objects at appropriate frequencies.

**Features:**
- Automatic frequency management
- Performance tracking
- Load balancing (skip low-weight ticks under high load)
- Time scale integration
- Dynamic tick level reassignment

### TimeController
Global time scale management with UI integration.

**Features:**
- Global time scale (0.5 = slower, 2.0 = faster)
- Pause/unpause functionality
- Preset time scales for UI
- Integration with TickManager

## Quick Start

### 1. Setup the System

```gdscript
# Add to your main scene
var tick_manager = TickManager.new()
add_child(tick_manager)

var time_controller = TimeController.new()
time_controller.tick_manager = tick_manager
add_child(time_controller)
```

### 2. Create a Tickable Object

```gdscript
extends RefCounted
class_name MyTickable

const Tickable = preload("res://addons/deep_thought/core/time/tickable.gd")
const TickSystem = preload("res://addons/deep_thought/core/time/tick_system.gd")

extends Tickable

func _init():
    tick_level = TickSystem.TickLevel.MEDIUM
    tick_weight = 1.0

func _tick(delta: float):
    # Your simulation logic here
    print("Ticked with delta: ", delta)
```

### 3. Register with TickManager

```gdscript
var my_tickable = MyTickable.new()
tick_manager.register_tickable(my_tickable, TickSystem.TickLevel.MEDIUM)
```

### 4. Control Time Scale

```gdscript
# Slow down time
time_controller.time_scale = 0.5

# Speed up time
time_controller.time_scale = 2.0

# Pause time
time_controller.time_paused = true
```

## Advanced Usage

### Dynamic Tick Level Changes

```gdscript
# Change tick level at runtime
tick_manager.change_tick_level(my_tickable, TickSystem.TickLevel.HIGH)
```

### Performance Monitoring

```gdscript
# Get statistics for a specific level
var stats = tick_manager.get_level_stats(TickSystem.TickLevel.MEDIUM)
print("Tick count: ", stats.tickable_count)
print("Total weight: ", stats.total_weight)
print("Last tick time: ", stats.last_tick_time)

# Get all statistics
var all_stats = tick_manager.get_all_stats()
```

### Load Balancing

```gdscript
# Enable automatic skipping of low-weight ticks under high load
tick_manager.skip_low_weight = true
tick_manager.performance_threshold = 16.0  # 60 FPS threshold
```

### UI Integration

```gdscript
# Connect time scale changes to UI
time_controller.time_scale_changed.connect(_on_time_scale_changed)

func _on_time_scale_changed(new_scale: float):
    update_time_ui(new_scale)

# Get presets for UI buttons
var presets = time_controller.get_presets()
for preset in presets:
    print("Preset ", preset.index, ": ", preset.label)
```

## Example Implementations

### Creature AI (HIGH frequency)
```gdscript
extends Tickable

func _init():
    tick_level = TickSystem.TickLevel.HIGH
    tick_weight = 2.0  # Important AI

func _tick(delta: float):
    # Update AI state
    update_behavior(delta)
    update_movement(delta)
    check_environment(delta)
```

### Weather System (RARE frequency)
```gdscript
extends Tickable

func _init():
    tick_level = TickSystem.TickLevel.RARE
    tick_weight = 0.5  # Background system

func _tick(delta: float):
    # Update weather conditions
    update_temperature(delta)
    update_humidity(delta)
    update_wind(delta)
```

### Physics System (IMMEDIATE frequency)
```gdscript
extends Tickable

func _init():
    tick_level = TickSystem.TickLevel.IMMEDIATE
    tick_weight = 3.0  # Critical system

func _tick(delta: float):
    # Update physics
    update_velocities(delta)
    check_collisions(delta)
    apply_forces(delta)
```

## Performance Considerations

### Tick Level Selection
- **IMMEDIATE**: Critical systems (physics, input)
- **HIGH**: Important systems (AI, player logic)
- **MEDIUM**: Standard systems (gameplay, UI updates)
- **LOW**: Background systems (ambient effects)
- **RARE**: Slow-changing systems (weather, day/night)

### Weight Assignment
- **3.0+**: Critical systems that must always run
- **1.0-2.0**: Important systems
- **0.5-1.0**: Standard systems
- **0.1-0.5**: Background systems that can be skipped

### Load Balancing
The system automatically skips low-weight ticks when performance is poor:
- Monitors tick processing time
- Skips ticks with weight < 0.5 under high load
- Configurable performance threshold

## Integration with Existing Systems

### Pawn System
```gdscript
# In PawnController
var ai_tickable = CreatureAITickable.new()
tick_manager.register_tickable(ai_tickable)
```

### World System
```gdscript
# In WorldPreview
var weather_tickable = WeatherTickable.new()
tick_manager.register_tickable(weather_tickable)
```

### Console Integration
```gdscript
# Add time control commands to developer console
func _cmd_time(args: Array) -> String:
    if args.is_empty():
        return "Usage: time [scale/pause/reset]"
    
    match args[0]:
        "pause":
            time_controller.toggle_pause()
            return "Time paused: " + str(time_controller.time_paused)
        "reset":
            time_controller.reset_speed()
            return "Time reset to normal"
        _:
            var scale = args[0].to_float()
            time_controller.set_time_scale(scale)
            return "Time scale set to: " + str(scale)
```

## Best Practices

1. **Choose appropriate tick levels** based on update frequency needs
2. **Assign weights carefully** - higher weights get priority under load
3. **Monitor performance** using the built-in statistics
4. **Use load balancing** for large simulations
5. **Register/unregister** tickables properly to avoid memory leaks
6. **Test with different time scales** to ensure simulation stability

## Troubleshooting

### Common Issues

**Ticks not running:**
- Check if tickable is registered
- Verify tick_level is correct
- Ensure tick_active is true

**Performance problems:**
- Reduce tick frequency for non-critical systems
- Lower tick weights for background systems
- Enable load balancing

**Time scale not working:**
- Verify TimeController is connected to TickManager
- Check that time_scale is not 0.0
- Ensure time_paused is false 