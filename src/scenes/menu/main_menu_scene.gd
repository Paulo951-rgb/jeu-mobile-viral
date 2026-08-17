extends Control
## MainMenuScene
## Responsive main menu. Shows app name, best score, coins, and primary
## actions (Play, Settings). All interactive elements are TouchButtons and
## live inside a SafeAreaContainer.

const GAME_SCENE := "res://src/scenes/game/GameScene.tscn"


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()
	GameManager.coins_changed.connect(_on_coins_changed)
	SaveManager.loaded.connect(_on_save_loaded)


func _build_ui() -> void:
	var root := SafeAreaContainer.new()
	root.set_anchors_preset(PRESET_FULL_RECT)
	add_child(root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(vbox)

	var title := Label.new()
	title.text = tr("APP_NAME")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1, 0.78, 0.2))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = tr("TAGLINE")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(subtitle)

	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 32)
	vbox.add_child(stats)

	_coins_label = _make_stat_label(stats, tr("COINS"), str(GameManager.coins))
	_best_label = _make_stat_label(stats, tr("BEST"), str(SaveManager.get_best_score()))

	vbox.add_child(_spacer())

	var play := _make_button(tr("PLAY"), true)
	play.pressed.connect(_on_play_pressed)
	vbox.add_child(play)

	var settings := _make_button(tr("SETTINGS"), false)
	settings.pressed.connect(_on_settings_pressed)
	vbox.add_child(settings)


var _coins_label: Label
var _best_label: Label


func _make_stat_label(parent: HBoxContainer, title: String, value: String) -> Label:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := Label.new()
	t.text = title.to_upper()
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	var v := Label.new()
	v.text = value
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_theme_font_size_override("font_size", 32)
	col.add_child(t)
	col.add_child(v)
	parent.add_child(col)
	return v


func _make_button(text: String, primary: bool) -> TouchButton:
	var b := TouchButton.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 28)
	b.custom_minimum_size = Vector2(320, AppConfig.MIN_TOUCH_SIZE_DP * 2)
	if primary:
		b.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12))
	return b


func _spacer() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 24)
	return c


func _on_play_pressed() -> void:
	SceneManager.goto_scene(GAME_SCENE)


func _on_settings_pressed() -> void:
	# Placeholder — settings panel to be added in a later milestone.
	pass


func _on_coins_changed(amount: int) -> void:
	if _coins_label:
		_coins_label.text = str(amount)


func _on_save_loaded() -> void:
	if _coins_label:
		_coins_label.text = str(GameManager.coins)
	if _best_label:
		_best_label.text = str(SaveManager.get_best_score())


func _notification(what: int) -> void:
	# Android hardware back button -> quit on main menu.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
