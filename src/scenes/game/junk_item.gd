extends Area2D
## JunkItem
## A collectible junk piece. Falls downward; emits collected when the player's
## Area2D overlaps it (area_entered, NOT body_entered — both nodes are Area2D,
## so body_entered would never fire), and exited_screen when it falls off the
## bottom (a miss), then auto-frees in either case.

signal collected(node: Area2D)
signal exited_screen(node: Area2D)

const FALL_SPEED := 220.0


func _ready() -> void:
	# area_entered is the correct Area2D<->Area2D detection signal in Godot 4.x.
	# body_entered only fires for PhysicsBody2D (RigidBody/CharacterBody/...),
	# so it would NEVER fire between two Area2D nodes — the collect would be dead.
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position.y += FALL_SPEED * delta
	var vp := get_viewport().get_visible_rect()
	if position.y > vp.end.y + 60:
		exited_screen.emit(self)
		queue_free()


func _on_area_entered(_other: Area2D) -> void:
	collected.emit(self)
