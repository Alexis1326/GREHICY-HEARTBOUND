extends Node3D
## Nivel: reinicia la partida al cargarse y calcula el progreso del jugador.

@export var level_id := "level_01"
@export var player_path: NodePath = "Player"
## El avance del nivel va de start_z a end_z (el nivel corre hacia -Z).
@export var start_z := 24.0
@export var end_z := -22.0

var _player: Node3D

func _ready() -> void:
	GameState.start_level(level_id)
	_player = get_node_or_null(player_path)

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	GameState.set_progress((start_z - _player.global_position.z) / (start_z - end_z))
