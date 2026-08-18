extends Node
## SceneManager
## Centralized scene transitions with a black fade and history for back
## navigation. Keeps boot->menu->game flow consistent across platforms.
## The fade layer lives on this autoload so it survives scene swaps.

signal scene_change_started(target: String)
signal scene_change_finished(target: String)

const FADE_DURATION := 0.18

var _current: String = ""
# Array[String] (not PackedStringArray) so we can use pop_back() in Godot 4.7.x.
var _history: Array[String] = []
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _transitioning: bool = false


func _ready() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	# Keep the fade alive while the tree is paused so transitions always finish.
	_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func goto_scene(path: String, record_history: bool = true) -> void:
	if _transitioning:
		return
	if _current == path and not _current.is_empty():
		return
	scene_change_started.emit(path)
	if record_history and not _current.is_empty():
		_history.append(_current)
	_current = path
	_transitioning = true
	# Block input while the screen is covered.
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tree := get_tree()
	tree.paused = false

	await _fade(0.0, 1.0)
	var err := tree.change_scene_to_file(path)
	if err != OK:
		push_error("SceneManager: failed to load scene %s" % path)
	await _fade(1.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transitioning = false
	scene_change_finished.emit(path)


func go_back() -> void:
	if _history.is_empty() or _transitioning:
		return
	var prev: String = _history.pop_back()
	_current = ""
	goto_scene(prev, false)


func current_scene() -> String:
	return _current


func can_go_back() -> bool:
	return not _history.is_empty()


func _fade(from_alpha: float, to_alpha: float) -> void:
	_fade_rect.color.a = from_alpha
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", to_alpha, FADE_DURATION)
	await tween.finished
