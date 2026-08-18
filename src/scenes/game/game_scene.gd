extends Node2D
## GameScene
## Core gameplay. The player moves (keyboard WASD/arrows on desktop, virtual
## joystick on mobile) to collect falling "junk" items, which convert to
## coins & score. Spawning ramps with level. Missing too many junk pieces ends
## the run. Designed to be cheap to render on low-end Android devices.
##
## Godot 4.7.x notes:
##   - Player & junk are both Area2D; detection uses area_entered (NOT
##     body_entered, which never fires between two Area2D nodes).
##   - Movement is velocity-based and clamped to the visible rect.
##   - The HUD is a separate CanvasLayer kept alive while paused.

const _JUNK_SCRIPT := preload("res://src/scenes/game/junk_item.gd")
const _JOYSTICK_SCRIPT := preload("res://src/ui/widgets/virtual_joystick.gd")

const PLAYER_SPEED := 520.0
const PLAYER_HALF := Vector2(70, 70)

var _player: Area2D
var _spawn_timer: Timer
var _junk_container: Node2D
var _hud: CanvasLayer
var _joystick: Control
var _joy_vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	_build_world()
	GameManager.start_run()
	GameManager.game_over.connect(_on_game_over)


func _build_world() -> void:
	_junk_container = Node2D.new()
	add_child(_junk_container)

	_player = Area2D.new()
	_player.collision_layer = 1
	_player.collision_mask = 2
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(140, 140)
	col.shape = rect
	_player.add_child(col)
	var sprite := ColorRect.new()
	sprite.color = Color(0.3, 0.8, 1.0)
	sprite.size = Vector2(140, 140)
	sprite.position = -PLAYER_HALF
	_player.add_child(sprite)
	add_child(_player)
	_player.position = get_viewport().get_visible_rect().get_center()

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = AppConfig.JUNK_SPAWN_INTERVAL_SEC
	_spawn_timer.timeout.connect(_spawn_junk)
	add_child(_spawn_timer)
	_spawn_timer.start()

	_hud = preload("res://src/ui/screens/game_hud.tscn").instantiate()
	# Keep the HUD interactive while the tree is paused so the pause overlay's
	# Resume button stays clickable (otherwise the player gets stuck in pause).
	_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_hud)

	if AppConfig.is_mobile():
		_build_joystick()


func _build_joystick() -> void:
	_joystick = Control.new()
	_joystick.set_script(_JOYSTICK_SCRIPT)
	# Bottom-left quadrant: comfortable for the thumb in portrait.
	_joystick.set_anchors_preset(Control.PRESET_FULL_RECT)
	_joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joystick.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_joystick)
	# Position the stick center near the bottom-left of the viewport.
	var vp := get_viewport().get_visible_rect()
	var safe := _joystick as VirtualJoystick
	safe.set_position(Vector2(vp.position.x + 60, vp.end.y - 320))
	safe.set_size(Vector2(280, 280))
	safe.move_vector_changed.connect(_on_joy_vector)


func _on_joy_vector(v: Vector2) -> void:
	_joy_vector = v


func _physics_process(delta: float) -> void:
	if GameManager.is_paused or not GameManager.is_game_active:
		return

	# Keyboard movement (desktop / bluetooth keyboards). The joystick vector is
	# additive so a physical keyboard + touch never cancel each other.
	var kb := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		kb.x -= 1.0
	if Input.is_action_pressed("move_right"):
		kb.x += 1.0
	if Input.is_action_pressed("move_up"):
		kb.y -= 1.0
	if Input.is_action_pressed("move_down"):
		kb.y += 1.0
	if kb.length() > 1.0:
		kb = kb.normalized()

	var move_vec := kb + _joy_vector
	if move_vec.length() > 1.0:
		move_vec = move_vec.normalized()

	_player.position += move_vec * PLAYER_SPEED * delta
	_clamp_player_to_viewport()


func _clamp_player_to_viewport() -> void:
	var vp := get_viewport().get_visible_rect()
	_player.position = Vector2(
		clamp(_player.position.x, vp.position.x + PLAYER_HALF.x, vp.end.x - PLAYER_HALF.x),
		clamp(_player.position.y, vp.position.y + PLAYER_HALF.y, vp.end.y - PLAYER_HALF.y)
	)


func _spawn_junk() -> void:
	# Use live child count so junk that already left (missed) or was collected
	# stops counting. A manual counter would desync and block spawning forever.
	if _junk_container.get_child_count() >= AppConfig.MAX_JUNK_ON_SCREEN:
		return
	var vp := get_viewport().get_visible_rect()
	var junk := _make_junk()
	junk.position = Vector2(randf_range(vp.position.x + 40, vp.end.x - 40), vp.position.y - 40)
	junk.collected.connect(_on_junk_collected)
	junk.exited_screen.connect(_on_junk_missed)
	_junk_container.add_child(junk)


func _make_junk() -> Area2D:
	# Build junk via script-first Area2D so _ready connects signals.
	var junk := Area2D.new()
	junk.set_script(_JUNK_SCRIPT)
	junk.collision_layer = 2
	junk.collision_mask = 1
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 36
	col.shape = c
	junk.add_child(col)
	var sprite := ColorRect.new()
	sprite.color = Color(0.95, 0.6, 0.2)
	sprite.size = Vector2(64, 64)
	sprite.position = Vector2(-32, -32)
	junk.add_child(sprite)
	return junk


func _on_junk_collected(junk: Area2D) -> void:
	junk.queue_free()
	GameManager.add_score(AppConfig.SCORE_PER_JUNK)
	GameManager.add_coins(AppConfig.COINS_PER_JUNK)
	HapticManager.light()
	# Speed up spawning as the level rises for escalating difficulty.
	var interval := max(0.4, AppConfig.JUNK_SPAWN_INTERVAL_SEC * pow(0.9, GameManager.level - AppConfig.STARTING_LEVEL))
	_spawn_timer.wait_time = interval


func _on_junk_missed(junk: Area2D) -> void:
	GameManager.register_miss()


func _on_game_over(_score: int) -> void:
	_spawn_timer.stop()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and GameManager.is_game_active:
		GameManager.set_paused(true)
