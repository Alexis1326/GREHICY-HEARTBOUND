extends Control
## Menú principal: punto de entrada del juego.

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_music("menu")
	AudioManager.attach_button_sounds(self)
	%Jugar.pressed.connect(_on_jugar)
	%Salir.pressed.connect(_on_salir)
	%Jugar.grab_focus()

func _on_jugar() -> void:
	get_tree().change_scene_to_file(Routes.SELECTOR)

func _on_salir() -> void:
	AudioManager.stop_all()
	get_tree().quit()
