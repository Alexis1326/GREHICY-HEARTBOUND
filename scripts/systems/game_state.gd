extends Node
## Estado global de la partida. Autoload: GameState.
## Solo guarda datos y emite señales; la HUD y el jugador reaccionan a ellas.

signal lives_changed(lives: int)
signal collectibles_changed(total: int)
signal progress_changed(value: float)
signal level_completed(level_id: String)

var max_lives := 3
var lives := 3
var collectibles := 0
var progress := 0.0
var level_id := ""

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
	level_completed.emit(id)
