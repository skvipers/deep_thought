extends Node
class_name WorldBase

signal chunk_loaded(chunk_pos: Vector3i)
signal chunk_unloaded(chunk_pos: Vector3i)

# Абстрактные методы, которые должны реализовать наследники
func get_chunk_at(world_pos: Vector3i) -> Chunk:
	push_error("get_chunk_at() must be implemented")
	return null

func world_to_local(world_pos: Vector3i) -> Vector3i:
	push_error("world_to_local() must be implemented")
	return Vector3i.ZERO

func get_chunk_size() -> Vector3i:
	push_error("get_chunk_size() must be implemented")
	return Vector3i.ZERO
