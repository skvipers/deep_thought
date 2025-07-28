extends Resource
class_name NoiseGenerator


@export var seed: int = 1337
@export var frequency: float = 0.01
@export var amplitude: float = 1.0
@export var offset: Vector2 = Vector2.ZERO
@export var noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_SIMPLEX
@export var fractal_type: FastNoiseLite.FractalType = FastNoiseLite.FRACTAL_NONE
@export var octaves: int = 3
@export var lacunarity: float = 2.0
@export var gain: float = 0.5

var noise := FastNoiseLite.new()

func _init():
	_update_noise()

func _update_noise():
	noise.seed = seed
	noise.noise_type = noise_type
	noise.frequency = frequency
	noise.fractal_type = fractal_type
	noise.fractal_octaves = octaves
	noise.fractal_lacunarity = lacunarity
	noise.fractal_gain = gain

func get_noise_2d(x: float, y: float) -> float:
	return noise.get_noise_2d(x + offset.x, y + offset.y) * amplitude

func get_noise_3d(x: float, y: float, z: float) -> float:
	return noise.get_noise_3d(x + offset.x, y, z + offset.y) * amplitude
