extends Node
## HapticManager
## Cross-platform vibration via Input.vibrate_handheld (Godot 4.x).
## Implemented on Android, iOS, Web; no-op on desktop. Toggleable via save
## settings for accessibility.

var enabled: bool = true


func light() -> void:
	_trigger(15)


func medium() -> void:
	_trigger(30)


func heavy() -> void:
	_trigger(60)


func _trigger(duration_ms: int) -> void:
	if not enabled or not AppConfig.is_mobile():
		return
	# Input.vibrate_handheld() is the correct Godot 4.x API. It is a no-op on
	# desktop platforms (Android/iOS/Web only). Requires the VIBRATE permission
	# in the Android export preset.
	Input.vibrate_handheld(duration_ms)
