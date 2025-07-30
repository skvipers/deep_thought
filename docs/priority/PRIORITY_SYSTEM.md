# Priority System Documentation

## Overview

The Priority System provides a flexible, modular framework for managing work priorities in colony simulation games like RimWorld or Dwarf Fortress. It handles automatic task assignment, priority calculations, and dynamic priority adjustments.

## Core Components

### PrioritySystem
Defines job types, priority scales, and calculation modes.

**Job Types:**
- `DOCTOR` - Medical treatment
- `CLEANING` - Area maintenance
- `CONSTRUCTION` - Building construction
- `HAULING` - Item transportation
- `MINING` - Resource extraction
- `FARMING` - Crop cultivation
- `COOKING` - Food preparation
- `RESEARCH` - Technology research
- `HUNTING` - Animal hunting
- `GUARD` - Security duties
- `CRAFTING` - Item creation
- `ANIMAL_HANDLING` - Animal care
- `ART` - Artistic work
- `SMITHING` - Metalworking
- `TAILORING` - Clothing creation

**Priority Scales:**
- `LOW` (1) - Lowest priority
- `BELOW_NORMAL` (2) - Below average priority
- `NORMAL` (3) - Standard priority
- `ABOVE_NORMAL` (4) - Above average priority
- `HIGH` (5) - Highest priority

**Priority Modes:**
- `ADDITIVE` - `pawn_priority * base_priority + boost_priority`
- `MULTIPLICATIVE` - `(pawn_priority + base_priority) * boost_priority`
- `WEIGHTED` - `pawn_priority * base_priority * boost_priority`

### Prioritizable
Base interface for objects that can have priorities assigned.

**Properties:**
- `base_priority` - Default priority level
- `boost_priority` - Temporary priority boost
- `job_type` - Type of work required
- `is_available` - Whether object is available for work
- `can_interrupt` - Whether work can be interrupted

**Methods:**
- `get_total_priority(pawn)` - Calculate total priority for a pawn
- `add_priority_boost(boost)` - Add temporary priority boost
- `can_be_worked_by(pawn)` - Check if pawn can work on this

### PriorityComponent
Node component that can be attached to world objects.

**Features:**
- Editor-friendly priority management
- Player-modifiable priorities
- Custom priority modifiers
- Signal-based priority changes

### Command
Represents a specific task or work order.

**Properties:**
- `job_type` - Type of work required
- `base_priority` - Default priority
- `boost_priority` - Temporary boost
- `target_object` - Object to work on
- `assigned_pawn` - Pawn assigned to task
- `state` - Current command state
- `progress` - Work completion progress

**States:**
- `PENDING` - Waiting for assignment
- `ASSIGNED` - Assigned to pawn
- `IN_PROGRESS` - Currently being worked on
- `COMPLETED` - Finished successfully
- `FAILED` - Failed to complete
- `CANCELLED` - Cancelled by player/system

### PriorityManager
Central manager for command assignment and priority calculations.

**Features:**
- Automatic command assignment
- Priority-based sorting
- Pawn capacity management
- Command progress tracking
- Dynamic priority adjustments

## Quick Start

### 1. Setup the System

```gdscript
# Add to your main scene
var priority_manager = PriorityManager.new()
add_child(priority_manager)

# Add pawns to the workforce
priority_manager.add_pawn(pawn1)
priority_manager.add_pawn(pawn2)
```

### 2. Create Commands

```gdscript
# Create a construction command
var construction_cmd = ConstructionCommand.new("House", PrioritySystem.PriorityScale.ABOVE_NORMAL)
priority_manager.add_command(construction_cmd)

# Create a medical command
var medical_cmd = MedicalCommand.new(wounded_pawn, "Heal Wounds", PrioritySystem.PriorityScale.HIGH)
priority_manager.add_command(medical_cmd)
```

### 3. Set Pawn Priorities

```gdscript
# Set pawn's job priorities
pawn.set_job_priority(PrioritySystem.JobType.DOCTOR, PrioritySystem.PriorityScale.HIGH)
pawn.set_job_priority(PrioritySystem.JobType.CLEANING, PrioritySystem.PriorityScale.LOW)
```

### 4. Add Priority Components to Objects

```gdscript
# Add priority component to a building
var priority_component = PriorityComponent.new()
priority_component.job_type = PrioritySystem.JobType.CONSTRUCTION
priority_component.base_priority = PrioritySystem.PriorityScale.ABOVE_NORMAL
building.add_child(priority_component)
```

## Advanced Usage

### Dynamic Priority Adjustments

```gdscript
# Add urgency boost to medical tasks
priority_manager.add_priority_boost_to_job_type(PrioritySystem.JobType.DOCTOR, 10)

# Add boost to specific command
medical_command.add_priority_boost(5)
```

### Custom Priority Components

```gdscript
# Create custom prioritizable object
class CustomPrioritizable extends Prioritizable:
    func _init():
        job_type = PrioritySystem.JobType.CRAFTING
        base_priority = PrioritySystem.PriorityScale.NORMAL
    
    func has_required_skills(pawn) -> bool:
        return pawn.get_skill_level("crafting") >= 2
```

### Command Requirements

```gdscript
# Set command requirements
command.requirements = {
    "skill_level": {"skill": "mining", "level": 2},
    "health": 50,
    "energy": 30,
    "distance": 100.0
}
```

### Priority Calculation Modes

```gdscript
# Use different calculation modes
priority_manager.priority_mode = PrioritySystem.PriorityMode.MULTIPLICATIVE
priority_manager.priority_mode = PrioritySystem.PriorityMode.WEIGHTED
```

## Example Implementations

### Pawn with Job Priorities

```gdscript
extends Node
class_name ExamplePawn

var job_priorities: Dictionary = {}

func _init():
    # Set default priorities
    for job_type in PrioritySystem.JobType.values():
        job_priorities[job_type] = PrioritySystem.PriorityScale.NORMAL
    
    # Set specific priorities
    job_priorities[PrioritySystem.JobType.DOCTOR] = PrioritySystem.PriorityScale.HIGH
    job_priorities[PrioritySystem.JobType.CLEANING] = PrioritySystem.PriorityScale.LOW

func get_job_priority(job_type: PrioritySystem.JobType) -> int:
    return job_priorities.get(job_type, PrioritySystem.PriorityScale.NORMAL)
```

### Building with Priority Component

```gdscript
extends Node3D
class_name Building

func _ready():
    # Add priority component
    var priority_component = PriorityComponent.new()
    priority_component.job_type = PrioritySystem.JobType.CONSTRUCTION
    priority_component.base_priority = PrioritySystem.PriorityScale.ABOVE_NORMAL
    add_child(priority_component)
    
    # Connect signals
    priority_component.work_started.connect(_on_work_started)
    priority_component.work_completed.connect(_on_work_completed)
```

### Custom Command Implementation

```gdscript
class CustomCommand extends Command:
    var custom_data: String = ""
    
    func _init(cmd_job_type: PrioritySystem.JobType, data: String):
        super._init(cmd_job_type)
        custom_data = data
        description = "Custom task: " + data
    
    func has_required_skills(pawn) -> bool:
        # Custom skill requirements
        return pawn.get_skill_level("custom_skill") >= 1
```

## UI Integration

### Priority Display

```gdscript
# Get priority information for UI
func get_priority_display(pawn) -> Dictionary:
    var display = {}
    for job_type in PrioritySystem.JobType.values():
        var job_name = PrioritySystem.JobType.keys()[job_type]
        display[job_name] = pawn.get_job_priority(job_type)
    return display
```

### Command Queue UI

```gdscript
# Get command information for UI
func get_command_queue_display() -> Array:
    var display = []
    for command in priority_manager.get_pending_commands():
        display.append({
            "name": command.get_display_name(),
            "priority": command.get_total_priority(null),
            "state": command.get_state_string(),
            "progress": command.progress
        })
    return display
```

### Priority Adjustment UI

```gdscript
# Handle priority changes from UI
func on_priority_changed(job_type: PrioritySystem.JobType, new_priority: int):
    selected_pawn.set_job_priority(job_type, new_priority)
    priority_manager.force_reassignment()
```

## Performance Considerations

### Command Assignment
- Commands are sorted by priority before assignment
- Pawns are evaluated based on skills and availability
- Assignment happens at regular intervals (configurable)

### Priority Calculations
- Cached priority calculations for performance
- Lazy evaluation of complex requirements
- Efficient sorting algorithms

### Memory Management
- Commands are automatically cleaned up when completed
- Pawn references are properly managed
- Signal connections are cleaned up

## Best Practices

1. **Set appropriate default priorities** for different job types
2. **Use priority boosts sparingly** to maintain system balance
3. **Implement proper skill requirements** for job types
4. **Monitor command queue performance** with large numbers of commands
5. **Use priority components** for world objects that need player control
6. **Implement proper cleanup** when pawns are removed or commands cancelled

## Troubleshooting

### Common Issues

**Commands not being assigned:**
- Check if pawns are available and have required skills
- Verify command requirements are met
- Ensure priority manager is processing assignments

**Priority calculations incorrect:**
- Check priority calculation mode
- Verify pawn job priorities are set correctly
- Ensure boost priorities are being applied properly

**Performance problems:**
- Reduce assignment interval for faster response
- Limit maximum commands per pawn
- Use priority boosts instead of creating many high-priority commands 