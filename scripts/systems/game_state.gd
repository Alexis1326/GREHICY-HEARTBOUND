extends Node
## Estado global de la partida. Autoload: GameState.
## Solo guarda datos y emite señales; la HUD y el jugador reaccionan a ellas.

signal lives_changed(lives: int)
signal collectibles_changed(total: int)
signal progress_changed(value: float)
signal level_completed(level_id: String)

const PROGRESS_PATH := "user://progress.cfg"

var max_lives := 3
var lives := 3
var collectibles := 0
var progress := 0.0
var level_id := ""

## Niveles completados: id -> coleccionables de su mejor partida.
var completed_levels := {}

func _ready() -> void:
	load_progress()

## El selector llama a esto antes de cambiar de escena.
func select_level(id: String) -> void:
	level_id = id

## Desbloqueado si es el primer nivel del catálogo o si el anterior
## ya está completado.
func is_level_unlocked(id: String) -> bool:
	if Levels.index_of(id) < 0:
		return false
	var previous := Levels.previous_id(id)
	return previous.is_empty() or completed_levels.has(previous)

func save_progress() -> void:
	var cfg := ConfigFile.new()
	for id in completed_levels:
		cfg.set_value(id, "coleccionables", int(completed_levels[id]))
	if cfg.save(PROGRESS_PATH) != OK:
		push_warning("No se pudo guardar el progreso: " + PROGRESS_PATH)

func load_progress() -> void:
	completed_levels = {}
	var cfg := ConfigFile.new()
	if cfg.load(PROGRESS_PATH) != OK:
		return  # primera partida: todavía no hay archivo
	for id in cfg.get_sections():
		completed_levels[id] = int(cfg.get_value(id, "coleccionables", 0))

## Llamar al crear la escena del nivel: reinicia la partida de ese nivel.
func start_level(id: String) -> void:
	level_id = id
	lives = max_lives
	collectibles = 0
	progress = 0.0
	lives_changed.emit(lives)
	collectibles_changed.emit(collectibles)
	progress_changed.emit(progress)

## Devuelve las vidas restantes.
func take_life() -> int:
	lives = maxi(lives - 1, 0)
	lives_changed.emit(lives)
	return lives

## Recupera una vida (cajas BONUS). Nunca supera el máximo.
func restore_life() -> int:
	lives = mini(lives + 1, max_lives)
	lives_changed.emit(lives)
	return lives

func add_collectible(amount: int = 1) -> void:
	collectibles += amount
	collectibles_changed.emit(collectibles)

## El progreso va de 0.0 a 1.0 y nunca retrocede.
func set_progress(value: float) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	if clamped <= progress:
		return
	progress = clamped
	progress_changed.emit(progress)

func complete_level(id: String) -> void:
	if level_id != id:
		return
	progress = 1.0
	progress_changed.emit(1.0)
	completed_levels[id] = maxi(int(completed_levels.get(id, 0)), collectibles)
	save_progress()
	level_completed.emit(id)
