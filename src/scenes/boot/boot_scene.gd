extends Control
## BootScene
## First scene loaded. Initializes autoloads, applies safe area, then routes
## to the main menu. Keeps heavy work off the main menu's first frame.

const MAIN_MENU := "res://src/scenes/menu/MainMenuScene.tscn"


func _ready() -> void:
	# Trigger any deferred init that needs the tree to be ready.
	# AppConfig / SaveManager already loaded via autoload _ready.
	_apply_orientation()
	# Defer one frame so the viewport has its real size for safe-area calc.
	call_deferred("_go_to_menu")


func _apply_orientation() -> void:
	# Single source of truth lives in AppConfig.ORIENTATION; mirror to runtime.
	var screen := DisplayServer.window_get_current_screen()
	match AppConfig.ORIENTATION:
		"portrait":
			DisplayServer.screen_set_orientation(screen, DisplayServer.SCREEN_PORTRAIT)
		"landscape":
			DisplayServer.screen_set_orientation(screen, DisplayServer.SCREEN_LANDSCAPE)


func _go_to_menu() -> void:
	SceneManager.goto_scene(MAIN_MENU, false)
