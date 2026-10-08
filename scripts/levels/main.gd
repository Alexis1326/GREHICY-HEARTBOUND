extends Node3D
## Escena del juego: carga el nivel que eligió el selector (GameState.level_id).
## El nivel ya no está incrustado en la escena para poder cambiar de uno.

func _ready() -> void:
	AudioManager.play_music("level")
	var id := GameState.level_id
	if Levels.index_of(id) < 0:
		var catalogo := Levels.all()
		id = String(catalogo[0].get("id", "")) if not catalogo.is_empty() else ""

	var ruta := Levels.scene_path(id)
	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		push_error("Escena de nivel no encontrada para '%s' (%s)" % [id, ruta])
		return
	add_child(load(ruta).instantiate())
