extends CharacterBody3D
class_name Player

## Controlador 3D en tercera persona.
## El cuerpo nunca rota (mejor para la colisión): solo rota el nodo Visual
## y la cámara, que cuelga de CameraPivot.

@export_group("Movimiento")
@export var move_speed := 6.5
@export var acceleration := 38.0
@export var deceleration := 30.0
@export var turn_speed := 14.0

@export_group("Salto")
@export var jump_velocity := 6.8
@export_range(0.0, 1.0) var jump_cut := 0.45
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.12
## 1 = salto simple. Cambiar a 2 activa el doble salto.
@export var max_jumps := 1

@export_group("Ataque giratorio")
@export var attack_duration := 0.45
@export var attack_cooldown := 0.55
## Alcance del giro en metros.
@export var attack_radius := 2.1
@export var attack_spin_speed := 22.0

@export_group("Danio")
@export var invulnerability_time := 1.5
@export var knockback_speed := 7.0
@export var knockback_up := 4.5
@export var death_delay := 0.9

@export_group("Camara")
@export var camera_height := 1.5
@export var camera_distance := 5.0
@export var camera_pitch := -18.0
@export_range(-75.0, 15.0) var camera_pitch_min := -65.0
@export_range(-75.0, 15.0) var camera_pitch_max := 10.0
@export var camera_sensitivity := 0.0035
@export var camera_follow_speed := 12.0

@export_group("Supervivencia")
## Por debajo de esta altura el jugador cayo a un abismo.
@export var fall_limit := -14.0

var _gravity: float = 9.8
var _coyote := 0.0
var _jump_buffer := 0.0
var _jumps_left := 1

var _attack_time := 0.0
var _attack_ready := 0.0
var _invuln := 0.0
var _dead := false

## Ultima superficie segura: donde reaparece si cae a un abismo.
var _safe_position := Vector3.ZERO

var _yaw_target := 0.0
var _pitch_target := 0.0

var _visual: Node3D
var _camera_pivot: Node3D
var _camera: Camera3D

func _ready() -> void:
	_visual = get_node("Visual")
	_camera_pivot = get_node("CameraPivot")
	_camera = _camera_pivot.get_node("Camera")

	_gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	_jumps_left = max_jumps
	_safe_position = global_position

	_camera.position = Vector3(0, 0, camera_distance)
	_camera_pivot.position = Vector3(0, camera_height, 0)
	_yaw_target = _camera_pivot.rotation.y
	_pitch_target = deg_to_rad(camera_pitch)
	_camera_pivot.rotation = Vector3(_pitch_target, _yaw_target, 0)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	# Seguimiento suave: horizontal rigido, vertical amortiguado.
	var follow := 1.0 - exp(-camera_follow_speed * delta)
	_camera_pivot.position.y = lerpf(_camera_pivot.position.y, camera_height, follow)
	_camera_pivot.rotation.x = lerp_angle(_camera_pivot.rotation.x, _pitch_target, follow)
	_camera_pivot.rotation.y = lerp_angle(_camera_pivot.rotation.y, _yaw_target, follow)

	if is_spinning():
		_visual.rotation.y += attack_spin_speed * delta

	if _invuln > 0.0:
		_invuln -= delta
		_visual.visible = fmod(_invuln, 0.24) < 0.16
	else:
		_visual.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw_target -= event.relative.x * camera_sensitivity
		_pitch_target -= event.relative.y * camera_sensitivity
		_pitch_target = clampf(_pitch_target, deg_to_rad(camera_pitch_min), deg_to_rad(camera_pitch_max))
	elif event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if _dead:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= _gravity * delta
		move_and_slide()
		return

	if is_on_floor():
		_coyote = coyote_time
		_jumps_left = max_jumps
	else:
		velocity.y -= _gravity * delta
		_coyote -= delta

	_jump_buffer -= delta
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time

	# _coyote permite saltar al salir de un borde; _jumps_left < max_jumps
	# permite los saltos extra en el aire (doble salto, fase posterior).
	if _jump_buffer > 0.0 and _jumps_left > 0 and (_coyote > 0.0 or _jumps_left < max_jumps):
		velocity.y = jump_velocity
		_jumps_left -= 1
		_coyote = 0.0
		_jump_buffer = 0.0

	# Cortar el salto al soltar: salto mas corto y mas preciso.
	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= jump_cut

	_update_attack(delta)
	_move(delta)
	move_and_slide()

	if is_on_floor():
		_safe_position = global_position

	if global_position.y < fall_limit:
		_fall_into_abyss()

## Movimiento relativo a la direccion de la camara (W = adelante en pantalla).
func _move(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3.ZERO

	if input != Vector2.ZERO:
		direction = Vector3(input.x, 0, input.y).rotated(Vector3.UP, _camera_pivot.rotation.y)
		direction.y = 0.0
		direction = direction.normalized()

	var current := Vector3(velocity.x, 0, velocity.z)
	var target := direction * move_speed
	var rate := acceleration if direction != Vector3.ZERO else deceleration
	current = current.move_toward(target, rate * delta)

	velocity.x = current.x
	velocity.z = current.z

	if direction != Vector3.ZERO and not is_spinning():
		_visual.rotation.y = lerp_angle(
			_visual.rotation.y,
			atan2(-direction.x, -direction.z),
			1.0 - exp(-turn_speed * delta)
		)

## --- Ataque giratorio -------------------------------------------------------

func is_spinning() -> bool:
	return _attack_time > 0.0

func _update_attack(delta: float) -> void:
	if _attack_ready > 0.0:
		_attack_ready -= delta

	if _attack_time > 0.0:
		_attack_time -= delta
		_hit_spin_targets()
	elif Input.is_action_just_pressed("attack") and _attack_ready <= 0.0:
		_attack_time = attack_duration
		_attack_ready = attack_duration + attack_cooldown

## Reparte el golpe a todo lo que esté en el grupo "hit_by_spin" y esté a tiro.
func _hit_spin_targets() -> void:
	var center := global_position + Vector3.UP * 0.9
	for node in get_tree().get_nodes_in_group("hit_by_spin"):
		if not is_instance_valid(node) or not node.has_method("hit_by_spin"):
			continue
		if node.global_position.distance_to(center) > attack_radius:
			continue
		node.call("hit_by_spin", global_position)

## --- Danio, vidas y muerte --------------------------------------------------

## Los enemigos llaman a esto. Ignora el golpe mientras dura la invulnerabilidad.
func take_damage(source: Vector3 = Vector3.ZERO) -> void:
	if _dead or _invuln > 0.0:
		return

	_invuln = invulnerability_time
	var remaining := GameState.take_life()

	var away := global_position - source
	away.y = 0.0
	if away.length_squared() < 0.001:
		away = -_visual.global_transform.basis.z

	velocity = away.normalized() * knockback_speed
	velocity.y = knockback_up
	_coyote = 0.0

	if remaining <= 0:
		_die()

func _fall_into_abyss() -> void:
	if _dead:
		return
	if GameState.take_life() <= 0:
		_die()
	else:
		respawn()
		_invuln = invulnerability_time

func _die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector3.ZERO
	await get_tree().create_timer(death_delay).timeout
	get_tree().reload_current_scene()

## Vuelve a la ultima superficie segura que piso (huecos y abismos).
func respawn() -> void:
	velocity = Vector3.ZERO
	global_position = _safe_position

## Fija el punto de reaparicion (checkpoints de nivel).
func set_checkpoint(origin: Vector3) -> void:
	_safe_position = origin
