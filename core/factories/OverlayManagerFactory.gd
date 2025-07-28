class_name OverlayManagerFactory

static func create_overlay_manager(world_base) -> OverlayManager:
	var manager = OverlayManager.new(world_base)
	return manager 