extends Control
## Selector de niveles: las tarjetas se construyen desde el catálogo.

@onready var _lista: GridContainer = %Lista

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_music("menu")
	_construir_tarjetas()
	%Volver.pressed.connect(_on_volver)
	# Después de construir las tarjetas: cubre también los botones nuevos.
	AudioManager.attach_button_sounds(self)
	_focar_primera_disponible()

func _construir_tarjetas() -> void:
	var niveles := Levels.all()
	%Aviso.visible = niveles.is_empty()
	for i in niveles.size():
		var nivel := niveles[i]
		var id := String(nivel.get("id", ""))
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(300, 130)
		boton.add_theme_font_size_override("font_size", 20)
		boton.text = _texto_tarjeta(i, id, String(nivel.get("titulo", id)))
		boton.disabled = not GameState.is_level_unlocked(id)
		boton.pressed.connect(_entrar.bind(id))
		_lista.add_child(boton)

func _texto_tarjeta(indice: int, id: String, titulo: String) -> String:
	var desbloqueado := GameState.is_level_unlocked(id)
	var estado := "Bloqueado"
	if desbloqueado:
		estado = "Completado" if GameState.completed_levels.has(id) else "Disponible"
	var coleccionables := int(GameState.completed_levels.get(id, 0))
	return "%d. %s\n%s\nColeccionables: %d" % [indice + 1, titulo, estado, coleccionables]

func _focar_primera_disponible() -> void:
	for tarjeta in _lista.get_children():
		if tarjeta is Button and not tarjeta.disabled:
			tarjeta.grab_focus()
			return
	%Volver.grab_focus()

func _entrar(id: String) -> void:
	GameState.select_level(id)
	get_tree().change_scene_to_file(Routes.JUEGO)

func _on_volver() -> void:
	get_tree().change_scene_to_file(Routes.MENU)
