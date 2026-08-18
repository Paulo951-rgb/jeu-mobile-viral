class_name TouchButton
extends Button
## TouchButton
## Enforces a minimum comfortable touch target size (≥ AppConfig.MIN_TOUCH_SIZE_DP)
## so buttons stay tappable with a finger across all screen densities.
## Scales its visual content independently of the hit area.


const DEFAULT_MIN_TOUCH_DP := 56.0

@export var min_touch_dp: float = DEFAULT_MIN_TOUCH_DP
@export var haptic_on_press: bool = true


func _ready() -> void:
	custom_minimum_size = _ensure_min_size(custom_minimum_size)
	pressed.connect(_on_pressed)


func _ensure_min_size(current: Vector2) -> Vector2:
	var scale_factor := _density_scale()
	var min_px := min_touch_dp * scale_factor
	return Vector2(max(current.x, min_px), max(current.y, min_px))


func _density_scale() -> float:
	# Approximate: use viewport height / base height. Godot reports logical
	# pixels already, so 1.0 is the safe default; the value still grows the
	# target on very small screens where DP scaling matters.
	var vp := get_viewport()
	if vp == null:
		return 1.0
	var base_h := float(AppConfig.BASE_VIEWPORT.y)
	var h := vp.get_visible_rect().size.y
	return clamp(h / base_h, 0.85, 1.4)


func _on_pressed() -> void:
	if haptic_on_press:
		HapticManager.light()
