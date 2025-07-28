extends Resource
class_name ChunkGenerationModule

func generate_chunk(buffer: MapBuffer, context: GenerationContext, chunk_position: Vector3i, chunk_size: Vector3i) -> void:
	# Abstract method — override in subclasses
	push_warning("generate_chunk() not implemented in %s" % self)
