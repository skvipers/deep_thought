extends Resource
class_name ChunkGeneratorRunner

func generate_chunk(buffer: MapBuffer, context: GenerationContext, chunk_position: Vector3i, chunk_size: Vector3i) -> void:
	for generator in context.generators:
		if generator is ChunkGenerationModule:
			generator.generate_chunk(buffer, context, chunk_position, chunk_size)
		else:
			push_warning("❌ Invalid generator in context: " + str(generator))
