# Deep Thought Addon

A comprehensive Godot 4 addon for procedural world generation, pawn management, and advanced terrain systems.

## Features

### 🌍 World Generation
- **Procedural Terrain Generation** - Advanced noise-based terrain generation
- **Chunk System** - Efficient chunk-based world rendering
- **Biome System** - Dynamic biome assignment and generation
- **Planet Generation** - Goldberg sphere-based planet generation

### 🎮 Pawn System
- **Modular Skeleton System** - Flexible bone and attachment management
- **Body Structure** - Comprehensive body part and prosthesis system
- **Visual Management** - Advanced visual component handling
- **Statistics System** - Modular stat blocks and modifiers

### 🎨 Overlay System
- **Dynamic Overlays** - Real-time terrain and object overlays
- **Brush System** - Customizable overlay brushes
- **Chunk Data** - Efficient overlay data management

### 🛠️ Development Tools
- **Logging System** - Modular logging with configurable levels
- **Editor Tools** - Custom editor extensions
- **Debug Tools** - Comprehensive debugging utilities

## Installation

### As Git Submodule
```bash
# In your Godot project
git submodule add https://github.com/skvipers/deep_thought.git addons/deep_thought
git submodule update --init --recursive
```

### Manual Installation
1. Download the latest release
2. Extract to your project's `addons/` directory
3. Enable the addon in Project Settings

## Usage

### Basic Setup
```gdscript
# Enable logging
LoggingConfig.setup_logging()
LoggingConfig.enable_pawn_logs()

# Create a pawn
var pawn = Pawn.new()
var config = PawnConfig.new()
config.skeleton_type = "humanoid"
pawn.config = config
```

### World Generation
```gdscript
# Create a world
var world = WorldBase.new()
var generator = BasicTerrainGenerator.new()
world.set_generator(generator)
```

## Documentation

- [Generation Overview](docs/generator/README.md)
- [Pawn System](docs/pawn/README.md)
- [Logging System](docs/logger/README.md)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📜 License

This project is licensed under the [MIT License](LICENSE).  
You are free to use it in both personal and commercial projects.

However...

---

## 🏢 Commercial Use Requires Sponsorship (Ethical Model)

If you're an **individual or indie dev** using this in a personal or open-source project — enjoy! ❤️

If you're a **company or using this framework in a commercial product**, please consider **supporting the project**.  
This is not a legal requirement, but a request for fairness.

Your sponsorship helps us:

- Continue active development and maintenance
- Add new features and compatibility for future versions of Godot
- Provide documentation and examples
- Stay motivated as developers 🌱

### 👉 [Patreon](https://patreon.com/deepthoughtgodot)  
or  
### 📬 Contact for custom licensing/support: skvipers@gmail.com

---

## ❤️ Contributing

Contributions are welcome!  
By submitting a pull request, you agree to license your code under the same MIT terms as the rest of the project. 