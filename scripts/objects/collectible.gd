extends Area3D
class_name Collectible

## Coleccionable reutilizable: gira, flota y se recoge al tocarlo.
## Al recogerse se anima un instante y desaparece, avisando a GameState.

@export var amount := 1
## Identificador del tipo de coleccionable: "corazon", "foto", "estrella"...
@export var kind := "corazon"
@export var spin_speed := 2.4
@export var bob_amplitude := 0.18
@export var bob_speed := 2.6

var _time := 0.0
var _base_y := 0.0
var _anchored := false
var _taken := false

func _ready() -> void:
	add_to_group("collectibles")

func _process(delta: float) -> void:
	if _taken:
		return
	# Se ancla en el primer frame para que funcione aunque la posición se
	# fije después de añadirlo a la escena (cajas que sueltan coleccionables).
	if not _anchored:
		_base_y = global_position.y
		_anchored = true
	_time += delta
	rotate_y(spin_speed * delta)
	global_position.y = _base_y + sin(_time * bob_speed) * bob_amplitude

func _on_body_entered(body: Node3D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	GameState.add_collectible(amount)
	AudioManager.play_sfx("collectible")
	set_deferred("monitoring", false)

	var visual := get_node_or_null("Visual")
	var tween := create_tween()
	if visual != null:
		tween.tween_property(visual, "scale", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
