extends CanvasLayer
## HUD: vidas, coleccionables y progreso del nivel.
## Solo lee el estado de GameState y reacciona a sus señales.

const HEART_ON := preload("res://assets/textures/heart.png")
const HEART_OFF := preload("res://assets/textures/heart_empty.png")

@onready var _lives_row: Control = %LivesRow
@onready var _heart1: TextureRect = %Heart1
@onready var _heart2: TextureRect = %Heart2
@onready var _heart3: TextureRect = %Heart3
@onready var _collectibles: Label = %Collectibles
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _progress_text: Label = %ProgressText
@onready var _banner: PanelContainer = %Banner
@onready var _banner_text: Label = %BannerText

var _hearts: Array[TextureRect] = []

func _ready() -> void:
	_hearts.assign([_heart1, _heart2, _heart3])

	GameState.lives_changed.connect(_on_lives_changed)
	GameState.collectibles_changed.connect(_on_collectibles_changed)
	GameState.progress_changed.connect(_on_progress_changed)
	GameState.level_completed.connect(_on_level_completed)

	_banner.visible = false
	_render_lives(GameState.lives)
	_collectibles.text = str(GameState.collectibles)
	_render_progress(GameState.progress)

func _on_lives_changed(lives: int) -> void:
	_render_lives(lives)
	# Destello rojo en la fila de corazones al cambiar la vida.
	_lives_row.modulate = Color(1, 0.35, 0.35)
	var tween := create_tween()
	tween.tween_property(_lives_row, "modulate", Color.WHITE, 0.4)

func _render_lives(lives: int) -> void:
	for i in _hearts.size():
		_hearts[i].texture = HEART_ON if i < lives else HEART_OFF

func _on_collectibles_changed(total: int) -> void:
	_collectibles.text = str(total)
	_collectibles.modulate = Color(1.6, 1.6, 1.6)
	var tween := create_tween()
	tween.tween_property(_collectibles, "modulate", Color.WHITE, 0.3)

func _on_progress_changed(value: float) -> void:
	_render_progress(value)

func _render_progress(value: float) -> void:
	_progress_bar.value = value * 100.0
	_progress_text.text = "PROGRESO  %d%%" % int(value * 100.0)

func _on_level_completed(_level_id: String) -> void:
	_banner.visible = true
	_banner_text.text = "¡NIVEL COMPLETADO!\n\nColeccionables: %d\nVidas restantes: %d" % [
		GameState.collectibles, GameState.lives
	]
