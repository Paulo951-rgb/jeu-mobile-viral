extends Node
## HapticManager
## Cross-platform vibration via DisplayServer.vibrate_handheld. No-op on
## desktop. Toggleable via save settings for accessibility.

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
	# Godot 4 portable API. Effectively a no-op on desktop builds.
	DisplayServer.vibrate_handheld(duration_ms)
