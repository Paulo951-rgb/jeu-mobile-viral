extends Node
## GameManager
## Owns the in-memory game state, emits signals on state changes, and bridges
## to SaveManager for persistence. UI/HUD subscribes to these signals.

signal coins_changed(amount: int)
signal level_changed(level: int)
signal score_changed(score: int)
signal misses_changed(misses: int)
signal game_started()
signal game_paused()
signal game_resumed()
signal game_over(final_score: int)

var coins: int = AppConfig.STARTING_COINS
var level: int = AppConfig.STARTING_LEVEL
var score: int = 0
var misses: int = 0
var is_game_active: bool = false
var is_paused: bool = false


func _notification(what: int) -> void:
	# Auto-pause when the app is backgrounded on mobile (Android/iOS) to save
	# battery/state. See Godot docs: NOTIFICATION_APPLICATION_PAUSED.
	if what == NOTIFICATION_APPLICATION_PAUSED and is_game_active and not is_paused:
		set_paused(true)


func reset_run() -> void:
	score = 0
	misses = 0
	level = AppConfig.STARTING_LEVEL
	is_paused = false
	score_changed.emit(score)
	level_changed.emit(level)
	misses_changed.emit(misses)


func start_run() -> void:
	reset_run()
	is_game_active = true
	game_started.emit()


func add_score(amount: int) -> void:
	score += max(amount, 0)
	# Level derives from score so it can never desync regardless of score
	# increments (handles variable rewards without skipping thresholds).
	var new_level := AppConfig.STARTING_LEVEL + int(score / AppConfig.SCORE_PER_LEVEL)
	if new_level != level:
		level = new_level
		level_changed.emit(level)
	score_changed.emit(score)


func add_coins(amount: int) -> void:
	coins += max(amount, 0)
	coins_changed.emit(coins)
	SaveManager.queue_save()


func spend_coins(amount: int) -> bool:
	if coins < amount or amount < 0:
		return false
	coins -= amount
	coins_changed.emit(coins)
	SaveManager.queue_save()
	return true


func add_level(amount: int = 1) -> void:
	level += max(amount, 0)
	level_changed.emit(level)
	SaveManager.queue_save()


func register_miss() -> void:
	misses += 1
	misses_changed.emit(misses)
	if misses >= AppConfig.MAX_MISSED_JUNK and is_game_active:
		end_run()


func end_run() -> void:
	if not is_game_active:
		return
	is_game_active = false
	# Persist immediately so the best score is up to date when the game-over
	# overlay reads it (queue_save is debounced and would lag behind).
	SaveManager.save_now()
	game_over.emit(score)


func set_paused(paused: bool) -> void:
	if not is_game_active:
		return
	is_paused = paused
	get_tree().paused = paused
	if paused:
		game_paused.emit()
	else:
		game_resumed.emit()
