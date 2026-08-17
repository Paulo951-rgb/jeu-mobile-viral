class_name SafeAreaContainer
extends MarginContainer
## SafeAreaContainer
## Applies device safe-area insets (notches, home indicator, status bar) so
## interactive UI never sits under hardware obstructions on iOS/Android.
## Works in-tool (no insets) and at runtime on device.


func _ready() -> void:
	_apply_safe_area()
	# Re-apply when the window is resized / rotated.
	get_viewport().size_changed.connect(_apply_safe_area)


func _apply_safe_area() -> void:
	# Window.get_safe_area() returns the safe rect in viewport-local coords on
	# all platforms (no insets on desktop). Convert to margins for the container.
	var win := get_window()
	if win == null:
		return
	var safe: Rect2i = win.get_safe_area()
	var vp_size := win.get_size()  # full viewport Vector2i
	add_theme_margin_override("margin_left", float(safe.position.x))
	add_theme_margin_override("margin_top", float(safe.position.y))
	add_theme_margin_override("margin_right", float(max(vp_size.x - safe.end.x, 0)))
	add_theme_margin_override("margin_bottom", float(max(vp_size.y - safe.end.y, 0)))
