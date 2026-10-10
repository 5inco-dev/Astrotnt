class_name SafeArea
extends RefCounted

# Insets to keep touch targets clear of notches, punch-holes and rounded
# corners on Android/iOS. DisplayServer.get_display_safe_area() reports the
# safe rectangle in physical screen pixels; convert to this window's local
# (pre-scale) UI space so `expand` stretch and content.scale both stay correct.
static func insets(window: Window) -> Dictionary:
	var screen_size := DisplayServer.screen_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if screen_size.x <= 0 or screen_size.y <= 0 or safe.size.x <= 0:
		return {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	var window_size: Vector2 = Vector2(window.size)
	var scale: Vector2 = window_size / Vector2(screen_size)
	return {
		"left": float(safe.position.x) * scale.x,
		"top": float(safe.position.y) * scale.y,
		"right": float(screen_size.x - safe.end.x) * scale.x,
		"bottom": float(screen_size.y - safe.end.y) * scale.y,
	}
