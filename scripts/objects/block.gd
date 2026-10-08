extends StaticBody3D
class_name Block

## Bloque reutilizable de escenario: define tamaño y color desde el inspector.
## El origen del bloque está en su centro, así que posicionarlo es directo.

@export var size := Vector3(4, 1, 4):
	set(value):
		size = value
		_refresh()

@export var color := Color(0.45, 0.5, 0.38):
	set(value):
		color = value
		_refresh()

@export var roughness := 0.9:
	set(value):
		roughness = value
		_refresh()

var _mesh_instance: MeshInstance3D
var _shape: CollisionShape3D

func _ready() -> void:
	_mesh_instance = get_node_or_null("MeshInstance3D")
	_shape = get_node_or_null("CollisionShape3D")
	_refresh()

## Genera la malla y la colisión a partir de los valores exportados.
func _refresh() -> void:
	if _mesh_instance == null or _shape == null or not is_inside_tree():
		return

	var box := BoxMesh.new()
	box.size = size
	_mesh_instance.mesh = box

	var box_shape := BoxShape3D.new()
	box_shape.size = size
	_shape.shape = box_shape

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	_mesh_instance.material_override = material
