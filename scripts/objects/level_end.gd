extends Area3D
class_name LevelEnd

## Fin del nivel: al entrar el jugador se emite level_completed en GameState.

@export var level_id := "level_01"
@export var spin_speed := 1.2

var _done := false
var _time := 0.0

func _ready() -> void:
	add_to_group("level_ends")

func _process(delta: float) -> void:
	_time += delta
	var visual := get_node_or_null("Visual")
	if visual != null:
		visual.rotation.y += spin_speed * delta
		visual.position.y = sin(_time * 2.0) * 0.12

func _on_body_entered(body: Node3D) -> void:
	if _done or not body.is_in_group("player"):
		return
	_done = true
	AudioManager.play_sfx("level_complete")
	GameState.complete_level(level_id)
