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
# Safe-area insets are applied at runtime via DisplayServer.

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


static func is_mobile() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")


static func is_debug() -> bool:
	return OS.is_debug_build()
