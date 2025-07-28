class_name OverlayGeneratorFactory

static func create_overlay_generator(overlay_manager: OverlayManager) -> OverlayGenerator:
	var generator = OverlayGenerator.new(overlay_manager)
	return generator 