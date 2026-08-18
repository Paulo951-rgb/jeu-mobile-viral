extends Node2D
## GameScene
## Core gameplay prototype. Player drags / taps to collect falling "junk"
## items, which convert to coins & score. Spawning ramps with level.
## Missing too many junk pieces ends the run. Designed to be cheap to render
## on low-end Android devices.

const _JUNK_SCRIPT := preload("res://src/scenes/game/junk_item.gd")

var _player: Area2D
var _spawn_timer: Timer
var _junk_container: Node2D
var _hud: CanvasLayer


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
	sprite.position = Vector2(-70, -70)
	_player.add_child(sprite)
	add_child(_player)
	_position_player_at_touch(get_viewport().get_visible_rect().get_center())

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


func _position_player_at_touch(pos: Vector2) -> void:
	# Keep the player inside the visible viewport so a touch near an edge
	# doesn't move the collector off-screen.
	var vp := get_viewport().get_visible_rect()
	var half := Vector2(70, 70)
	_player.position = Vector2(
		clamp(pos.x, vp.position.x + half.x, vp.end.x - half.x),
		clamp(pos.y, vp.position.y + half.y, vp.end.y - half.y)
	)


func _input(event: InputEvent) -> void:
	# Touch (mobile) + mouse (desktop) so the game is testable on Windows/macOS.
	if event is InputEventScreenTouch and event.pressed:
		_position_player_at_touch(event.position)
	elif event is InputEventScreenDrag:
		_position_player_at_touch(event.position)
	elif event is InputEventMouseButton and event.pressed:
		_position_player_at_touch(event.position)
	elif event is InputEventMouseMotion and event.button_mask != 0:
		_position_player_at_touch(event.position)


func _spawn_junk() -> void:
	# Use live child count so junk that already left (missed) or was collected
	# stops counting. A manual counter would desync and block spawning forever.
	if _junk_container.get_child_count() >= AppConfig.MAX_JUNK_ON_SCREEN:
		return
	var vp := get_viewport().get_visible_rect()
	var junk := _make_junk()
	junk.position = Vector2(randf_range(vp.position.x + 40, vp.end.x - 40), vp.position.y - 40)
	junk.body_collected.connect(_on_junk_collected)
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
