class_name ChunkFactory

static func create_chunk(chunk_scene: PackedScene) -> Chunk:
	return chunk_scene.instantiate() 