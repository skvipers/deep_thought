# Priority System Module

A flexible, modular priority system for colony simulation games like RimWorld or Dwarf Fortress, built for Godot 4.

## Features

- **Global Work Priorities** - Per-pawn job priorities (1-5 scale, configurable)
- **Command System** - Tasks with base priority, boost priority, and requirements
- **Priority Components** - Attachable to world objects for player modification
- **Automatic Assignment** - Smart task assignment based on priorities and skills
- **Dynamic Adjustments** - Runtime priority changes and urgency boosts
- **UI Integration** - Editor-friendly components and signal-based updates
- **Modular Design** - Extensible for custom job types and priority calculations

## Quick Start

```gdscript
# Setup priority manager
var priority_manager = PriorityManager.new()
add_child(priority_manager)

# Add pawns to workforce
priority_manager.add_pawn(pawn1)
priority_manager.add_pawn(pawn2)

# Register job types (optional - use DefaultJobTypes for demo)
DefaultJobTypes.initialize_default_job_types()

# Create and add tasks
var construction_task = ConstructionTask.new("House", 4)
priority_manager.add_task(construction_task)

# Set pawn priorities
pawn.set_job_priority("construction", 4)  # Above normal
pawn.set_job_priority("cleaning", 1)     # Low priority
```

## Files

- `priority_system.gd` - Core definitions (priority scales, calculation modes, job type registry)
- `default_job_types.gd` - Demo class for initializing default job types (optional)
- `prioritizable.gd` - Base interface for prioritizable objects
- `priority_component.gd` - Node component for world objects
- `work_task.gd` - Task/work order system
- `priority_manager.gd` - Central task assignment and management
- `PRIORITY_SYSTEM.md` - Comprehensive documentation

## Testing

Use the test scene `test/PrioritySystemTest.tscn` to test the priority system functionality.

## Core Concepts

### Priority Calculation
```
Final Priority = pawn_priority * base_priority + boost_priority
```

### Job Types (Demo Defaults)
- **doctor** - Medical treatment (High priority)
- **construction** - Building construction (Above normal)
- **mining** - Resource extraction (Above normal)
- **cooking** - Food preparation (Above normal)
- **hauling** - Item transportation (Normal)
- **cleaning** - Area maintenance (Normal)
- **farming** - Crop cultivation (Normal)
- **research** - Technology research (Below normal)
- **crafting** - Item creation (Normal)
- **guard** - Security duties (High priority)

*Note: These are demo defaults. Games can register their own job types.*

### Priority Scales
- **LOW** (1) - Lowest priority
- **BELOW_NORMAL** (2) - Below average
- **NORMAL** (3) - Standard priority
- **ABOVE_NORMAL** (4) - Above average
- **HIGH** (5) - Highest priority

## Usage Examples

### Creating Work Tasks
```gdscript
# Register job types first
PrioritySystem.set_priority_scale(1, 5, 3)
PrioritySystem.register_job_type("construction", "Construction", 4)
PrioritySystem.register_job_type("medical", "Medical", 5)
PrioritySystem.register_job_type("mining", "Mining", 4)

# Or use demo defaults
DefaultJobTypes.initialize_default_job_types()

# Construction task
var construction_task = ConstructionTask.new("House", 4)
priority_manager.add_task(construction_task)

# Medical task (high priority)
var medical_task = MedicalTask.new(wounded_pawn, "Heal Wounds", 5)
priority_manager.add_task(medical_task)

# Mining task
var mining_task = MiningTask.new("Iron", mine_location, 4)
priority_manager.add_task(mining_task)
```

### Setting Pawn Priorities
```gdscript
# Set specific job priorities (using string IDs)
pawn.set_job_priority("medical", 5)      # High priority
pawn.set_job_priority("cleaning", 1)     # Low priority  
pawn.set_job_priority("construction", 4) # Above normal priority
```

### Adding Priority Components
```gdscript
# Add to buildings or other world objects
var priority_component = PriorityComponent.new()
priority_component.job_type = "construction"
priority_component.base_priority = 4
building.add_child(priority_component)
```

### Dynamic Priority Adjustments
```gdscript
# Add urgency boost to medical tasks
priority_manager.add_priority_boost_to_job_type("medical", 10)

# Add boost to specific task
medical_task.add_priority_boost(5)
```

## Integration

The priority system integrates seamlessly with:
- **Pawn System** - Job priorities and skill requirements
- **World System** - Priority components on buildings and zones
- **UI System** - Priority displays and adjustment controls
- **Developer Console** - Priority management commands

## Performance

- **Efficient Assignment** - Priority-based sorting and smart pawn selection
- **Configurable Intervals** - Adjustable command assignment frequency
- **Capacity Management** - Limit commands per pawn to prevent overload
- **Memory Management** - Automatic cleanup of completed commands

## Customization

### Adding New Job Types
```gdscript
# Register custom job types
PrioritySystem.register_job_type("custom_job", "Custom Job", 3, "Description of custom job")
PrioritySystem.register_job_type("specialist", "Specialist", 4, "Specialized work")

# Use in tasks and pawn priorities
pawn.set_job_priority("custom_job", 4)
var custom_task = CustomTask.new("Custom Work", 3)
```

### Custom Priority Components
```gdscript
class CustomPrioritizable extends Prioritizable:
    func _init():
        job_type = "custom_job"
        base_priority = 3
    
    func has_required_skills(pawn) -> bool:
        return pawn.get_skill_level("custom_skill") >= 2
```

### Custom Tasks
```gdscript
class CustomTask extends WorkTask:
    func _init(task_job_type: String, task_priority: int):
        super._init(task_job_type, task_priority)
        description = "Custom task"
    
    func has_required_skills(pawn) -> bool:
        return pawn.get_skill_level("custom_skill") >= 1
```

## Best Practices

1. **Set appropriate default priorities** for different job types
2. **Use priority boosts sparingly** to maintain system balance
3. **Implement proper skill requirements** for job types
4. **Monitor command queue performance** with large numbers of commands
5. **Use priority components** for world objects that need player control
6. **Implement proper cleanup** when pawns are removed or commands cancelled

See `PRIORITY_SYSTEM.md` for detailed documentation and examples. 