extends Node
## AppConfig
## Central, easily-modifiable configuration for the whole game.
##
## Change values here (no need to dig through project.godot or per-scene
## settings) to control app identity, orientation, gameplay tuning, etc.
## Keep secrets OUT of this file — store keys via env / signing config only.

# ---- App identity (mirrors project.godot; change in BOTH places) -------------
const APP_NAME := "JunkYardRush"
const BUNDLE_IDENTIFIER := "com.yourstudio.junkyardrush"
const COMPANY_NAME := "Your Studio"
const VERSION := "0.1.0"
const VERSION_CODE := 1

# ---- Orientation -------------------------------------------------------------
## "portrait" | "landscape". Changing this also requires updating
## window/handheld/orientation in project.godot and rotating UI anchors.
const ORIENTATION := "portrait"

# ---- Design / responsive -----------------------------------------------------
const BASE_VIEWPORT := Vector2i(720, 1280)
# Minimum comfortable touch target (Google: 48dp, Apple: 44pt).
const MIN_TOUCH_SIZE_DP := 56.0
# Safe-area insets are applied at runtime via SafeAreaContainer (Window.get_safe_area()).

# ---- Gameplay tuning ---------------------------------------------------------
const STARTING_COINS := 0
const STARTING_LEVEL := 1
const JUNK_SPAWN_INTERVAL_SEC := 1.2
const MAX_JUNK_ON_SCREEN := 18

# ---- Save --------------------------------------------------------------------
const SAVE_SLOT := "user://save_data.json"

# ---- Audio -------------------------------------------------------------------
const DEFAULT_MASTER_VOLUME_DB := 0.0
const DEFAULT_MUTE_ON_FOCUS_LOST := true

# ---- Stats / analytics toggle (no external SDK wired yet) -------------------
const ANALYTICS_ENABLED := false

# ---- Localization ------------------------------------------------------------
const TRANSLATIONS_CSV := "res://src/data/translations.csv"
const FALLBACK_LOCALE := "en"


func _ready() -> void:
	# Load translations at runtime (CSV is the source of truth; this avoids
	# depending on Godot's translation importer and never blocks startup).
	_load_translations()


func is_mobile() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")


func is_debug() -> bool:
	return OS.is_debug_build()


func _load_translations() -> void:
	if not FileAccess.file_exists(TRANSLATIONS_CSV):
		push_warning("AppConfig: translations CSV not found: %s" % TRANSLATIONS_CSV)
		return
	var file := FileAccess.open(TRANSLATIONS_CSV, FileAccess.READ)
	if file == null:
		push_warning("AppConfig: cannot open translations CSV")
		return
	var lines: Array[String] = []
	while not file.eof_reached():
		var line := file.get_line()
		if line.is_empty() or line.begins_with("#"):
			continue
		lines.append(line)
	file.close()
	if lines.size() < 2:
		return

	var header := _parse_csv_line(lines[0])
	if header.size() < 2:
		return
	# header[0] == "keys"; header[1..] are locale codes.
	var langs: Array[String] = []
	for i in range(1, header.size()):
		langs.append(header[i])

	var translations: Dictionary = {}  # locale -> Translation
	for lang in langs:
		var t := Translation.new()
		t.locale = lang
		translations[lang] = t

	for i in range(1, lines.size()):
		var fields := _parse_csv_line(lines[i])
		if fields.size() < 2:
			continue
		var key: String = fields[0]
		for li in range(0, langs.size()):
			if li + 1 >= fields.size():
				break
			var value: String = fields[li + 1]
			if value.is_empty():
				continue
			(translations[langs[li]] as Translation).add_message(key, value)

	for lang in langs:
		TranslationServer.add_translation(translations[lang])

	# Prefer the system locale if we ship it; otherwise use the fallback.
	var sys := TranslationServer.get_locale()
	if not translations.has(sys):
		TranslationServer.set_locale(FALLBACK_LOCALE)


func _parse_csv_line(line: String) -> PackedStringArray:
	return line.split(",")
