class_name SafeAreaContainer
extends MarginContainer
## SafeAreaContainer
## Applies device safe-area insets (notches, home indicator, status bar) so
## interactive UI never sits under hardware obstructions on iOS/Android.
## Falls back to zero margins on desktop / in-editor (no insets).
##
## Godot 4.7.x API note:
##   Window.get_safe_area() does NOT exist. The cross-platform source of truth
##   is DisplayServer.get_display_safe_area() (returns a Rect2i in screen
##   coordinates). We convert that to viewport-relative margins using the main
##   window's position and size. On desktop the safe area is the whole screen,
##   so the computed insets clamp to zero — no error, no lost UI.


func _ready() -> void:
	_apply_safe_area()
	# Re-apply when the window is resized / rotated.
	var vp := get_viewport()
	if vp != null:
		vp.size_changed.connect(_apply_safe_area)


func _apply_safe_area() -> void:
	# Default: no insets (desktop / editor / fallback).
	var left := 0
	var top := 0
	var right := 0
	var bottom := 0

	var win := get_window()
	if win != null:
		var vp_size := win.get_size()  # Vector2i, full client size
		var win_pos := Vector2i.ZERO
		if DisplayServer.has_method("window_get_position"):
			win_pos = DisplayServer.window_get_position()
		if DisplayServer.has_method("get_display_safe_area"):
			# Rect2i in screen coords covering the safe (unobstructed) region.
			var safe := DisplayServer.get_display_safe_area()
			# Intersection of the safe area with the window, expressed as
			# per-edge insets relative to the window's client rect. Clamped so
			# a desktop window inside a full-screen safe area yields zero.
			left = max(0, safe.position.x - win_pos.x)
			top = max(0, safe.position.y - win_pos.y)
			right = max(0, (win_pos.x + vp_size.x) - safe.end.x)
			bottom = max(0, (win_pos.y + vp_size.y) - safe.end.y)

	# MarginContainer theme constants (the only supported way to set margins
	# in Godot 4.x; there is no add_theme_margin_override).
	add_theme_constant_override("margin_left", left)
	add_theme_constant_override("margin_top", top)
	add_theme_constant_override("margin_right", right)
	add_theme_constant_override("margin_bottom", bottom)
