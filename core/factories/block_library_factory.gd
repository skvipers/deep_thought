class_name BlockLibraryFactory

static func create_block_library(blocks: Array) -> BlockLibrary:
	var library = BlockLibrary.new()
	library.blocks = blocks
	library.ensure_initialized()
	return library 