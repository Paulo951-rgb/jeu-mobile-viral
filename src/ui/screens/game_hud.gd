extends CanvasLayer
## GameHud
## On-screen score/coins/level display + pause button, all inside a
## SafeAreaContainer so they avoid notches / home indicators.


func _ready() -> void:
	layer = 10
	_build_ui()
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.game_over.connect(_on_game_over)


func _unhandled_input(event: InputEvent) -> void:
	# Escape (desktop) / mapped pause key toggles pause, mirroring the on-screen
	# pause button so the game is fully playable on Windows/macOS.
	if event.is_action_pressed("pause") and GameManager.is_game_active:
		_on_pause_pressed()
		get_viewport().set_input_as_handled()


var _score_label: Label
var _coins_label: Label
var _level_label: Label
var _overlay: Control


func _build_ui() -> void:
	var safe := SafeAreaContainer.new()
	safe.set_anchors_preset(PRESET_FULL_RECT)
	add_child(safe)

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 24)
	safe.add_child(top)

	_score_label = _make_stat(top, tr("SCORE"), "0")
	_coins_label = _make_stat(top, tr("COINS"), str(GameManager.coins))
	_level_label = _make_stat(top, tr("LEVEL"), str(GameManager.level))

	# Pause button, top-right, large touch target.
	var pause := TouchButton.new()
	pause.text = "⏸"
	pause.custom_minimum_size = Vector2(AppConfig.MIN_TOUCH_SIZE_DP * 2, AppConfig.MIN_TOUCH_SIZE_DP * 2)
	pause.pressed.connect(_on_pause_pressed)
	top.add_child(pause)


func _make_stat(parent: HBoxContainer, title: String, value: String) -> Label:
	var col := VBoxContainer.new()
	var t := Label.new()
	t.text = title.to_upper()
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	var v := Label.new()
	v.text = value
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_theme_font_size_override("font_size", 28)
	col.add_child(t)
	col.add_child(v)
	parent.add_child(col)
	return v


func _on_pause_pressed() -> void:
	GameManager.set_paused(not GameManager.is_paused)
	if GameManager.is_paused:
		_show_overlay(tr("PAUSED"), tr("RESUME"))


func _show_overlay(title: String, action_text: String) -> void:
	_hide_overlay()
	_overlay = Control.new()
	_overlay.set_anchors_preset(PRESET_FULL_RECT)
	var color := ColorRect.new()
	color.color = Color(0, 0, 0, 0.55)
	color.set_anchors_preset(PRESET_FULL_RECT)
	_overlay.add_child(color)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	_overlay.add_child(vbox)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 48)
	vbox.add_child(t)
	var b := TouchButton.new()
	b.text = action_text
	b.custom_minimum_size = Vector2(280, AppConfig.MIN_TOUCH_SIZE_DP * 2)
	b.pressed.connect(_on_resume_pressed)
	vbox.add_child(b)
	add_child(_overlay)


func _hide_overlay() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null


func _on_resume_pressed() -> void:
	_hide_overlay()
	if GameManager.is_game_active:
		GameManager.set_paused(false)
	else:
		# Game over overlay -> back to main menu.
		SceneManager.goto_scene("res://src/scenes/menu/MainMenuScene.tscn")


func _on_score_changed(s: int) -> void:
	if _score_label: _score_label.text = str(s)


func _on_coins_changed(c: int) -> void:
	if _coins_label: _coins_label.text = str(c)


func _on_level_changed(l: int) -> void:
	if _level_label: _level_label.text = str(l)


func _on_game_over(final_score: int) -> void:
	var best := SaveManager.get_best_score()
	var title := "%s\n%s: %d\n%s: %d" % [tr("GAME_OVER"), tr("SCORE"), final_score, tr("BEST"), best]
	if final_score >= best and final_score > 0:
		title += "\n★"
	_show_overlay(title, tr("MENU"))
