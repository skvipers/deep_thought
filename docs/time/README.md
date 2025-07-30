# Time System Module

A flexible, performant tick system for managing simulation updates at different frequencies in Godot 4.

## Features

- **Multiple Tick Frequencies**: IMMEDIATE, HIGH, MEDIUM, LOW, RARE
- **Centralized Management**: Single TickManager handles all tick processing
- **Time Scale Control**: Global time scale with pause/unpause functionality
- **Performance Optimization**: Load balancing with automatic low-weight tick skipping
- **Dynamic Reassignment**: Change tick levels and weights at runtime
- **UI Integration**: Preset time scales and percentage controls
- **Performance Monitoring**: Built-in statistics and performance tracking

## Quick Start

```gdscript
# Add to your main scene
var tick_manager = TickManager.new()
add_child(tick_manager)

var time_controller = TimeController.new()
time_controller.tick_manager = tick_manager
add_child(time_controller)

# Create and register a tickable
var my_tickable = MyTickable.new()
tick_manager.register_tickable(my_tickable, TickSystem.TickLevel.MEDIUM)
```

## Files

- `tick_system.gd` - Core tick system definitions and enums
- `tickable.gd` - Base interface for tickable objects
- `tick_manager.gd` - Central tick processing and management
- `time_controller.gd` - Global time scale management
- `test_tick_system.gd` - Demonstration and testing script
- `TICK_SYSTEM.md` - Comprehensive documentation

## Usage Examples

### Creature AI (HIGH frequency)
```gdscript
extends Tickable

func _init():
    tick_level = TickSystem.TickLevel.HIGH
    tick_weight = 2.0

func _tick(delta: float):
    update_ai_behavior(delta)
    update_movement(delta)
```

### Weather System (RARE frequency)
```gdscript
extends Tickable

func _init():
    tick_level = TickSystem.TickLevel.RARE
    tick_weight = 0.5

func _tick(delta: float):
    update_weather_conditions(delta)
```

### Time Control
```gdscript
# Slow down time
time_controller.time_scale = 0.5

# Speed up time
time_controller.time_scale = 2.0

# Pause time
time_controller.time_paused = true
```

## Performance Considerations

- **IMMEDIATE**: Critical systems (physics, input)
- **HIGH**: Important systems (AI, player logic)
- **MEDIUM**: Standard systems (gameplay, UI updates)
- **LOW**: Background systems (ambient effects)
- **RARE**: Slow-changing systems (weather, day/night)

## Integration

The tick system integrates seamlessly with:
- Pawn system (AI updates)
- World system (weather, day/night cycles)
- Developer console (time control commands)
- UI systems (time scale controls)

See `TICK_SYSTEM.md` for detailed documentation and examples. 