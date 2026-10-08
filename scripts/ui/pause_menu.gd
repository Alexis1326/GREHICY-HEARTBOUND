extends Control
## Pausa del nivel (Esc). Va en modo ALWAYS para leer la tecla con el árbol
## pausado; el resto del mundo se detiene por process_mode heredado.

func _ready() -> void:
	visible = false
	AudioManager.attach_button_sounds(self)
	%Continuar.pressed.connect(_on_continuar)
	%Menu.pressed.connect(_on_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_on_continuar()
		else:
			_pausar()

func _pausar() -> void:
	get_tree().paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%Continuar.grab_focus()

func _on_continuar() -> void:
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(Routes.MENU)
