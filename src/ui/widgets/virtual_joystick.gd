class_name VirtualJoystick
extends Control
## VirtualJoystick
## Touch-stick for mobile movement. Emits `move_vector` (Vector2, length 0..1,
## world-axis aligned: x=right, y=down) while touched, and a zero vector on
## release. No-op input on desktop (the game uses keyboard there), but the
## stick still renders so the player sees the control.
##
## Godot 4.7.x API note: built only from Control/InputEvent/TouchScreenButton-
## free APIs (plain _input + draw_circle via _draw). No experimental classes.

signal move_vector_changed(vec: Vector2)

const RADIUS := 140.0
const KNOB_RADIUS := 60.0

var _active: bool = false
var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Touch input is captured directly so we never block UI below the stick.
	var vp := get_viewport()
	if vp != null:
		vp.size_changed.connect(_on_size_changed)
	_on_size_changed()


func _on_size_changed() -> void:
	# Anchor the stick to the bottom-center of the screen, inside the safe area.
	# The GameScene positions this Control; we just size/center the knob origin.
	_origin = size * 0.5
	_knob = _origin
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _active:
			# Only grab touches that start within our rect.
			if get_rect().has_point(event.position):
				_active = true
				_touch_index = event.index
				_origin = event.position
				_knob = _origin
				queue_redraw()
		elif not event.pressed and event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		var delta := event.position - _origin
		if delta.length() > RADIUS:
			delta = delta.normalized() * RADIUS
		_knob = _origin + delta
		_emit_vector(delta / RADIUS)
		queue_redraw()


func _release() -> void:
	_active = false
	_touch_index = -1
	_knob = _origin
	_emit_vector(Vector2.ZERO)
	queue_redraw()


func _emit_vector(v: Vector2) -> void:
	move_vector_changed.emit(v)


func _draw() -> void:
	# Outer ring + knob. Plain colors, placeholder art.
	draw_circle(_origin, RADIUS, Color(1, 1, 1, 0.08))
	draw_arc(_origin, RADIUS, 0, TAU, 64, Color(1, 1, 1, 0.25), 4.0)
	draw_circle(_knob, KNOB_RADIUS, Color(1, 1, 1, 0.35))
