extends Node2D
## GameScene
## Core gameplay prototype. Player drags / taps to collect falling "junk"
## items, which convert to coins & score. Spawning ramps with level.
## Designed to be cheap to render on low-end Android devices.

var _player: Area2D
var _spawn_timer: Timer
var _junk_container: Node2D
var _hud: CanvasLayer
var _active_junk: int = 0


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
	add_child(_hud)


func _position_player_at_touch(pos: Vector2) -> void:
	_player.position = pos


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_position_player_at_touch(event.position)
	elif event is InputEventScreenDrag:
		_position_player_at_touch(event.position)


func _spawn_junk() -> void:
	if _active_junk >= AppConfig.MAX_JUNK_ON_SCREEN:
		return
	var vp := get_viewport().get_visible_rect()
	var junk := _make_junk()
	junk.position = Vector2(randf_range(vp.position.x + 40, vp.end.x - 40), vp.position.y - 40)
	junk.body_collected.connect(_on_junk_collected)
	_junk_container.add_child(junk)
	_active_junk += 1


func _make_junk() -> Area2D:
	# Build junk via script-first Area2D so _ready connects signals.
	var script := load("res://src/scenes/game/junk_item.gd")
	var junk := Area2D.new()
	junk.set_script(script)
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
	_active_junk = max(_active_junk - 1, 0)
	GameManager.add_score(10)
	GameManager.add_coins(1)
	# Level up every 100 score.
	if GameManager.score > 0 and GameManager.score % 100 == 0:
		GameManager.add_level(1)
		_spawn_timer.wait_time = max(0.4, _spawn_timer.wait_time * 0.9)


func _on_game_over(_score: int) -> void:
	_spawn_timer.stop()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and GameManager.is_game_active:
		GameManager.set_paused(true)
