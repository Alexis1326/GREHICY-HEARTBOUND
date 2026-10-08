extends StaticBody3D
class_name Crate

## Caja reutilizable. Se rompe con el ataque giratorio (grupo "hit_by_spin").
## Tipos iniciales: NORMAL sin premio, BONUS recupera vida,
## CONTENTS suelta coleccionables. Para añadir tipos, ampliar el enum.

enum Kind { NORMAL, BONUS, CONTENTS }

@export var kind: Kind = Kind.NORMAL
## Cuántos coleccionables suelta el tipo CONTENTS.
@export var contents_amount := 3
## Escena que se instancia al romperse (solo la usa CONTENTS).
@export var collectible_scene: PackedScene

var _broken := false

func _ready() -> void:
	add_to_group("hit_by_spin")

## Recibe el impacto del giro. `source` es la posición del atacante.
func hit_by_spin(source: Vector3 = Vector3.ZERO) -> void:
	if _broken:
		return
	_broken = true
	AudioManager.play_sfx("bonus" if kind == Kind.BONUS else "crate_break")
	if kind == Kind.BONUS:
		GameState.restore_life()
	_release_contents()
	_play_break()

func _release_contents() -> void:
	if kind != Kind.CONTENTS or collectible_scene == null:
		return
	for i in contents_amount:
		var item := collectible_scene.instantiate()
		get_parent().add_child(item)
		item.position = position + Vector3(
			randf_range(-0.7, 0.7),
			0.7 + i * 0.12,
			randf_range(-0.7, 0.7)
		)

## La caja deja de chocar y se encoge antes de desaparecer.
func _play_break() -> void:
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	var visual := get_node_or_null("Visual")
	var tween := create_tween()
	if visual != null:
		tween.tween_property(visual, "scale", Vector3(1.25, 0.05, 1.25), 0.07)
		tween.parallel().tween_property(visual, "rotation:y", visual.rotation.y + 0.6, 0.16)
		tween.tween_property(visual, "scale", Vector3.ZERO, 0.12)
	tween.tween_callback(queue_free)
