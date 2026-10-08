extends Area3D
class_name Checkpoint

## Marca el punto de reaparicion. El primer jugador que toca la zona guarda
## su posición, así que al morir vuelve a aparecer aquí.

@export var active_color := Color(0.35, 0.95, 0.55)

var _activated := false

func _ready() -> void:
	add_to_group("checkpoints")

func _on_body_entered(body: Node3D) -> void:
	if _activated or not body.has_method("set_checkpoint"):
		return
	_activated = true
	body.set_checkpoint(global_position)
	_announce()

## Pinta la marca de verde y hace un rebote: retroalimentación visible.
func _announce() -> void:
	var visual := get_node_or_null("Visual")
	if visual == null:
		return

	var material := StandardMaterial3D.new()
	material.albedo_color = active_color
	material.emission_enabled = true
	material.emission = active_color
	material.emission_energy_multiplier = 0.9

	for child in visual.get_children():
		if child is MeshInstance3D:
			child.material_override = material

	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector3(1.3, 1.3, 1.3), 0.16)
	tween.tween_property(visual, "scale", Vector3.ONE, 0.2)
