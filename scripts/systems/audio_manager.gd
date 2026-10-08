extends Node
## Audio global. Autoload: AudioManager.
##
## - Crea los buses "Music" y "SFX".
## - Los efectos salen de un grupo de reproductores, así que se solapan.
## - La música hace fundido cruzado entre pistas y sigue sonando en pausa
##   (el nodo va en modo ALWAYS, igual que los clics de los menús).
## - stop_all() corta el audio antes de salir del juego (ver su comentario).

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"

## Efectos disponibles: clave usada en el código -> fichero.
const SFX := {
	"jump": "jump.wav",
	"spin": "spin.wav",
	"damage": "damage.wav",
	"death": "death.wav",
	"crate_break": "crate_break.wav",
	"bonus": "bonus.wav",
	"collectible": "collectible.wav",
	"checkpoint": "checkpoint.wav",
	"level_complete": "level_complete.wav",
	"enemy_die": "enemy_die.wav",
	"click": "click.wav",
}

## Pistas de música: clave -> fichero.
const MUSIC := {
	"menu": "menu_theme.wav",
	"level": "level_theme.wav",
}

## Reproductores simultáneos para efectos.
const POOL_SIZE := 6
const MUSIC_FADE := 0.8
const SILENCE_DB := -50.0

var _sfx: Dictionary = {}
var _tracks: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _music: Array[AudioStreamPlayer] = []
var _music_index := 0
var _music_key := ""
var _music_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_create_players()
	_load_streams()

## Cierre de ventana (X o Alt+F4). Se recibe en cualquier nodo, incluidos los
## autoloads, y Godot cierra el juego al terminar este mismo frame.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		stop_all()

## Para todo el audio. Hay que llamarlo ANTES de get_tree().quit(): el servidor
## de audio solo suelta la reproducción en su siguiente tick, así que si el
## proceso se corta con música en marcha Godot avisa de fugas al terminar.
func stop_all() -> void:
	if _music_tween != null:
		_music_tween.kill()
		_music_tween = null
	for player in _pool:
		player.stop()
	for player in _music:
		player.stop()
	_music_key = ""

## Reproduce un efecto. Las claves desconocidas solo avisan por consola.
func play_sfx(key: String) -> void:
	if not _sfx.has(key):
		push_warning("Efecto de audio desconocido: " + key)
		return
	var player := _free_player()
	player.stream = _sfx[key]
	player.play()

## Cambia la música con fundido cruzado. Si esa pista ya suena, no hace nada.
func play_music(key: String) -> void:
	if key == _music_key:
		return
	if not _tracks.has(key):
		push_warning("Pista de música desconocida: " + key)
		return
	_music_key = key

	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()

	var saliente := _music[_music_index]
	_music_index = 1 - _music_index
	var entrante := _music[_music_index]
	entrante.stream = _tracks[key]
	entrante.volume_db = SILENCE_DB
	entrante.play()

	_music_tween = create_tween()
	_music_tween.tween_property(entrante, "volume_db", 0.0, MUSIC_FADE)
	if saliente.playing:
		_music_tween.parallel().tween_property(saliente, "volume_db", SILENCE_DB, MUSIC_FADE)
		_music_tween.tween_callback(saliente.stop)

## Conecta el sonido de clic a todos los botones de una escena (una sola
## llamada por escena en _ready, después de construir sus botones).
func attach_button_sounds(root: Node) -> void:
	for node in root.find_children("*", "Button", true, false):
		(node as Button).pressed.connect(play_sfx.bind("click"))

## Primer reproductor libre; si no queda ninguno, roba el primero.
func _free_player() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	return _pool[0]

func _create_players() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_pool.append(player)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = SILENCE_DB
		add_child(player)
		_music.append(player)

func _load_streams() -> void:
	for key in SFX:
		var path := SFX_DIR + String(SFX[key])
		if ResourceLoader.exists(path):
			_sfx[key] = load(path)
		else:
			push_warning("Efecto no encontrado: " + path)

	for key in MUSIC:
		var path := MUSIC_DIR + String(MUSIC[key])
		if not ResourceLoader.exists(path):
			push_warning("Música no encontrada: " + path)
			continue
		var stream := load(path) as AudioStreamWAV
		if stream != null:
			# Bucle: si no, la pista se corta al terminar.
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.data.size() / 2.0)  # mono de 16 bits
			_tracks[key] = stream

## Crea el bus si el proyecto no lo trae todavía.
func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")
