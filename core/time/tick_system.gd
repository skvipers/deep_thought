extends RefCounted
class_name TickSystem

## Tick frequency levels for different simulation priorities
enum TickLevel {
	IMMEDIATE = 0,  # Every frame (60 FPS)
	HIGH = 1,       # Every 2 frames (30 FPS)
	MEDIUM = 2,     # Every 4 frames (15 FPS)
	LOW = 3,        # Every 8 frames (7.5 FPS)
	RARE = 4        # Every 16 frames (3.75 FPS)
} 