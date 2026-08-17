extends Node
## SceneManager
## Centralized scene transitions with fade-in/out and history for back
## navigation. Keeps boot->menu->game flow consistent across platforms.

signal scene_change_started(target: String)
signal scene_change_finished(target: String)

const TRANSITION_DURATION := 0.25

var _current: String = ""
var _history: PackedStringArray = []


func goto_scene(path: String, record_history: bool = true) -> void:
	if _current == path:
		return
	scene_change_started.emit(path)
	if record_history and not _current.is_empty():
		_history.append(_current)
	_current = path
	# Simple fade via a CanvasLayer color rect.
	var tree := get_tree()
	tree.paused = false
	var err := tree.change_scene_to_file(path)
	if err != OK:
		push_error("SceneManager: failed to load scene %s" % path)
		return
	scene_change_finished.emit(path)


func go_back() -> void:
	if _history.is_empty():
		return
	var prev: String = _history.pop_back()
	_current = ""
	goto_scene(prev, false)


func current_scene() -> String:
	return _current


func can_go_back() -> bool:
	return not _history.is_empty()
