extends CharacterBody3D
class_name PatrolEnemy

## Enemigo sencillo: patrulla entre dos puntos, persigue al jugador si se
## acerca y le hace daño por contacto. Muere con el ataque giratorio.
## Para añadir tipos nuevos, crear otra escena con este mismo contrato:
## grupo "hit_by_spin", método hit_by_spin() y llamada a take_damage().

enum Mode { PATROL, CHASE }

@export_group("Patrulla")
@export_enum("X", "Z") var axis := 0
@export var patrol_distance := 3.5
@export var patrol_speed := 1.8

@export_group("Deteccion")
@export var detect_radius := 4.5
@export var chase_speed := 2.6
@export var contact_radius := 1.2
@export var contact_damage := 1

var _origin := Vector3.ZERO
var _direction := 1.0
var _gravity := 9.8
var _dead := false
var _player: Node3D
var _visual: Node3D
var _edge_ray: RayCast3D

func _ready() -> void:
	add_to_group("hit_by_spin")
	_origin = global_position
	_gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	_edge_ray = get_node_or_null("EdgeRay")
	_visual = get_node("Visual")
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if _dead:
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = -0.1

	var direction := _desired_direction()
	if _can_walk(direction):
		var speed := _current_speed(direction)
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Nada delante: no avanza y, si patrulla, invierte el sentido.
		_direction = -_direction
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	_try_damage_player()

	# Solo gira el modelo: el cuerpo queda alineado con el mundo para que
	# el rayo de suelo (target_position) siempre apunte en dirección real.
	if direction != Vector3.ZERO:
		_visual.rotation.y = lerp_angle(
			_visual.rotation.y,
			atan2(-direction.x, -direction.z),
			0.15
		)

## Dirección horizontal objetivo según el modo actual.
func _desired_direction() -> Vector3:
	if _player == null or not is_instance_valid(_player):
		return _patrol_direction()

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() <= detect_radius:
		if to_player.length() > 0.05:
			return to_player.normalized()
	return _patrol_direction()

func _patrol_direction() -> Vector3:
	var offset := global_position - _origin
	var along := offset.x if axis == 0 else offset.z
	if along * _direction >= patrol_distance:
		_direction = -1.0
	elif along * _direction <= -patrol_distance:
		_direction = 1.0

	if axis == 0:
		return Vector3(_direction, 0, 0)
	return Vector3(0, 0, _direction)

func _current_speed(direction: Vector3) -> float:
	return chase_speed if _is_chasing(direction) else patrol_speed

func _is_chasing(direction: Vector3) -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	return to_player.length() <= detect_radius and direction.is_equal_approx(to_player.normalized())

## Se queda en el suelo: apunta el rayo hacia adelante y hacia abajo, y no
## avanza si delante no hay nada (evita caerse por los bordes).
func _can_walk(direction: Vector3) -> bool:
	if _edge_ray == null or not is_on_floor():
		return true
	_edge_ray.target_position = Vector3(direction.x, 0.0, direction.z) * 1.2 + Vector3.DOWN * 1.6
	_edge_ray.force_raycast_update()
	return _edge_ray.is_colliding()

func _try_damage_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _player.has_method("take_damage"):
		return
	if global_position.distance_to(_player.global_position) > contact_radius:
		return
	_player.take_damage(global_position)

## Lo llama el jugador durante el ataque giratorio.
func hit_by_spin(source: Vector3 = Vector3.ZERO) -> void:
	if _dead:
		return
	_dead = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	var away := global_position - source
	away.y = 0.0
	var spin := away.normalized() * 0.9 if away.length_squared() > 0.001 else Vector3.RIGHT * 0.9

	var tween := create_tween()
	tween.tween_property(_visual, "rotation:y", _visual.rotation.y + signf(spin.x) * 1.4, 0.18)
	tween.parallel().tween_property(_visual, "scale", Vector3(1.15, 0.1, 1.15), 0.12)
	tween.tween_property(_visual, "scale", Vector3.ZERO, 0.14)
	tween.tween_callback(queue_free)
