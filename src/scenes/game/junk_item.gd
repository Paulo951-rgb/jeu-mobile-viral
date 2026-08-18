extends Area2D
## JunkItem
## A collectible junk piece. Falls downward; emits body_collected when the
## player overlaps it, and exited_screen when it falls off the bottom (a miss),
## then auto-frees in either case.

signal body_collected(node: Area2D)
signal exited_screen(node: Area2D)

const FALL_SPEED := 220.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.y += FALL_SPEED * delta
	var vp := get_viewport().get_visible_rect()
	if position.y > vp.end.y + 60:
		exited_screen.emit(self)
		queue_free()


func _on_body_entered(_body: Node) -> void:
	body_collected.emit(self)
