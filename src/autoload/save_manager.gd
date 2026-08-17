extends Node
## SaveManager
## Cross-platform local persistence using user:// (maps to app sandbox on
## Android/iOS). Uses JSON for human-readable, debuggable saves.
##
## NOTE: This is local-only save data. Cloud sync / server credentials should
## NEVER be embedded in code — wire them via env / signing config when needed.

const SAVE_VERSION := 1

signal saved()
signal loaded()

var _dirty: bool = false
var _save_timer: Timer
var _best_score: int = 0


func _ready() -> void:
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 1.0
	_save_timer.timeout.connect(_flush_save)
	add_child(_save_timer)
	load_save()


## Mark state dirty; actual write is debounced to avoid IO spam mid-gameplay.
func queue_save() -> void:
	_dirty = true
	_save_timer.start()


func save_now() -> void:
	_flush_save()


func _flush_save() -> void:
	if not _dirty:
		return
	_dirty = false

	var data := {
		"version": SAVE_VERSION,
		"coins": GameManager.coins,
		"level": GameManager.level,
		"best_score": max(get_best_score(), GameManager.score),
		"settings": {
			"master_volume_db": AudioManager.master_volume_db,
			"muted": AudioManager.is_muted,
			"haptics_enabled": HapticManager.enabled,
		},
	}

	var file := FileAccess.open(AppConfig.SAVE_SLOT, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write save file: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	saved.emit()


func load_save() -> bool:
	if not FileAccess.file_exists(AppConfig.SAVE_SLOT):
		return false
	var file := FileAccess.open(AppConfig.SAVE_SLOT, FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot read save file")
		return false
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: corrupt save file, ignoring")
		return false
	var data: Dictionary = parsed

	# Version-gated migration hook for future schema changes.
	var v: int = int(data.get("version", 0))
	if v > SAVE_VERSION:
		push_warning("SaveManager: save from newer version, loading best-effort")

	GameManager.coins = int(data.get("coins", AppConfig.STARTING_COINS))
	GameManager.level = int(data.get("level", AppConfig.STARTING_LEVEL))
	_best_score = int(data.get("best_score", 0))

	var settings: Dictionary = data.get("settings", {})
	AudioManager.master_volume_db = float(settings.get("master_volume_db", AppConfig.DEFAULT_MASTER_VOLUME_DB))
	AudioManager.is_muted = bool(settings.get("muted", false))
	HapticManager.enabled = bool(settings.get("haptics_enabled", true))

	loaded.emit()
	GameManager.coins_changed.emit(GameManager.coins)
	GameManager.level_changed.emit(GameManager.level)
	return true


func get_best_score() -> int:
	return _best_score


func reset_all() -> void:
	_best_score = 0
	GameManager.coins = AppConfig.STARTING_COINS
	GameManager.level = AppConfig.STARTING_LEVEL
	queue_save()
