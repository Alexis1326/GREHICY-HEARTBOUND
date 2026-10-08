extends Node

## Verificación automatizada del proyecto. Se ejecuta en modo headless:
##   Godot --headless --path . res://tools/probe.tscn
## Con ventana además guarda un fotograma en f1_frame.png.

var _player: Player
var _camera: Camera3D
var _hud: CanvasLayer
var _nivel_completado := false
## Progreso real del jugador, para devolverlo al terminar las pruebas.
var _progreso_previo := {}

func _ready() -> void:
	GameState.level_completed.connect(_on_level_completed)
	_progreso_previo = GameState.completed_levels.duplicate()

	# --- FASE 3 ---
	_test_catalogo()
	_test_rutas()
	await _test_menu_principal()
	await _test_selector()
	_test_guardado()

	var main: PackedScene = load("res://scenes/main/Main.tscn")
	add_child(main.instantiate())

	await _frames(40)

	_player = get_tree().get_first_node_in_group("player") as Player
	_camera = _find_camera(self)
	_hud = get_node_or_null("/root/Probe/Main/HUD")
	_diagnostico_rutas()

	# --- FASE 1 ---
	_check_camera()
	_test_hud_inicial()
	await _test_pausa()
	await _test_audio()
	await _reposo()
	await _test_movement()
	await _test_jump()
	await _test_fall()
	await _test_sin_salto_aereo()
	await _test_doble_salto()
	GameState.start_level("level_01")

	# --- FASE 2 ---
	await _test_recoger_coleccionable()
	await _test_caja_normal()
	await _test_caja_con_contenido()
	await _test_caja_bonus()
	await _test_enemigo_dania()
	await _test_enemigo_derrotado()
	await _test_checkpoint()
	await _test_fin_de_nivel()
	# Fotograma con el nivel completado: banner, barra llena y contadores.
	await _capturar_frame("C:/Users/ferney.naranjo/AppData/Local/Temp/opencode/f1_fin.png")

	# Estado limpio para el fotograma final.
	GameState.start_level("level_01")
	if _hud != null:
		var banner := _hud.get_node_or_null("Root/Banner")
		if banner != null:
			banner.visible = false
	_player.velocity = Vector3.ZERO
	_player.global_position = Vector3(0, 0.2, 24)
	await _frames(15)
	await _capturar_frame()

	# Navegación real entre pantallas (último: crea escenas sueltas).
	await _test_flujo()

	# Devuelve el progreso del jugador tal como estaba antes de las pruebas.
	GameState.completed_levels = _progreso_previo
	GameState.save_progress()

	# El audio se corta unos frames antes de salir: el servidor de audio solo
	# suelta la reproducción en su siguiente tick (ver AudioManager.stop_all).
	AudioManager.stop_all()
	await _frames(3)

	print("PROBE_DONE")
	get_tree().quit()

func _on_level_completed(_id: String) -> void:
	_nivel_completado = true

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

## Busca por nombre dentro del nivel: no depende de la ruta exacta y evita
## confundir con nodos homónimos de la HUD.
func _ruta(ruta: String) -> Node:
	var nivel := get_node_or_null("/root/Probe/Main/Level_01_Test")
	if nivel == null:
		return null
	return nivel.find_child(ruta.get_file(), true, false)

func _diagnostico_rutas() -> void:
	var main := get_node_or_null("/root/Probe/Main")
	if main == null:
		print("PROBE diag main=null")
		return
	print("PROBE diag main_hijos=", _nombres(main))
	var nivel := get_node_or_null("/root/Probe/Main/Level_01_Test")
	if nivel == null:
		print("PROBE diag nivel=null")
		return
	print("PROBE diag nivel_hijos=", _nombres(nivel))
	var col := nivel.get_node_or_null("Collectibles")
	if col != null:
		print("PROBE diag coleccionables=", _nombres(col))
	else:
		print("PROBE diag coleccionables=null")

func _nombres(nodo: Node) -> PackedStringArray:
	var salida := PackedStringArray()
	for hijo in nodo.get_children():
		salida.append(String(hijo.name))
	return salida

# --- FASE 3 -----------------------------------------------------------------

func _test_catalogo() -> void:
	var niveles := Levels.all()
	var ids := PackedStringArray()
	for nivel in niveles:
		ids.append(String(nivel.get("id", "")))
	var escena := Levels.scene_path("level_01")
	print("PROBE catalogo niveles=", niveles.size(), " ids=", ids,
		" escena_level01=", escena,
		" existe=", not escena.is_empty() and ResourceLoader.exists(escena))

func _test_rutas() -> void:
	var ok := true
	for ruta in [Routes.MENU, Routes.SELECTOR, Routes.JUEGO]:
		if not ResourceLoader.exists(ruta):
			ok = false
			print("PROBE ruta_inexistente=", ruta)
	print("PROBE rutas existen=", ok)

func _test_menu_principal() -> void:
	var escena: PackedScene = load(Routes.MENU)
	if escena == null:
		print("PROBE menu_principal carga=false")
		return
	var menu := escena.instantiate()
	add_child(menu)
	var titulo := menu.get_node_or_null("Centro/Titulo") as Label
	var jugar := menu.get_node_or_null("Centro/Jugar") as Button
	var salir := menu.get_node_or_null("Centro/Salir") as Button
	var conectado := jugar != null and jugar.pressed.get_connections().size() > 0 \
		and salir != null and salir.pressed.get_connections().size() > 0
	print("PROBE menu_principal titulo=", titulo.text if titulo else "?",
		" botones=", jugar != null and salir != null,
		" botones_conectados=", conectado)
	await _capturar_frame("C:/Users/ferney.naranjo/AppData/Local/Temp/opencode/f3_menu.png")
	menu.queue_free()
	await _frames(2)

func _test_selector() -> void:
	var escena: PackedScene = load(Routes.SELECTOR)
	if escena == null:
		print("PROBE selector carga=false")
		return
	var selector := escena.instantiate()
	add_child(selector)
	var lista := selector.get_node_or_null("Centro/Lista")
	var tarjetas := lista.get_child_count() if lista != null else 0
	var primera_ok := false
	if tarjetas > 0:
		var primera := lista.get_child(0) as Button
		primera_ok = primera != null and not primera.disabled
	var volver := selector.get_node_or_null("Centro/Volver") as Button
	var conectado := volver != null and volver.pressed.get_connections().size() > 0
	print("PROBE selector tarjetas=", tarjetas, " primera_desbloqueada=", primera_ok,
		" volver_conectado=", conectado)
	await _capturar_frame("C:/Users/ferney.naranjo/AppData/Local/Temp/opencode/f3_selector.png")
	selector.queue_free()
	await _frames(2)

## Guardar, vaciar y volver a cargar: el progreso debe sobrevivir al reinicio.
func _test_guardado() -> void:
	GameState.completed_levels = {"level_01": 7}
	GameState.save_progress()
	GameState.completed_levels = {}
	GameState.load_progress()
	var recuperado := int(GameState.completed_levels.get("level_01", 0)) == 7
	var desbloqueado := GameState.is_level_unlocked("level_01")
	var desconocido := not GameState.is_level_unlocked("level_inexistente")
	print("PROBE guardado recuperado=", recuperado,
		" level01_desbloqueado=", desbloqueado,
		" desconocido_bloqueado=", desconocido)

## Esc pausa el árbol y lo reanuda: la única salida de un nivel en marcha.
func _test_pausa() -> void:
	var pausa := get_node_or_null("/root/Probe/Main/PauseMenu")
	if pausa == null:
		print("PROBE pausa existe=false")
		return
	_teclear_escape(true)
	await _frames(2)
	# ¿La tecla inyectada se reconoce como ui_cancel? (diagnóstico)
	var accion_ok := Input.is_action_pressed("ui_cancel")
	await _frames(1)
	var abierta: bool = get_tree().paused and pausa.visible
	_teclear_escape(false)
	await _frames(2)
	_teclear_escape(true)
	await _frames(3)
	var cerrada: bool = not get_tree().paused and not pausa.visible
	_teclear_escape(false)
	await _frames(2)
	# Si la pausa se quedara abierta arrastraría el resto de pruebas.
	var atascado := get_tree().paused
	if atascado:
		get_tree().paused = false
		pausa.visible = false
	print("PROBE pausa abre=", abierta, " cierra=", cerrada,
		" accion_reconocida=", accion_ok,
		" sin_atasco=", not atascado)

func _teclear_escape(pulsada: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.physical_keycode = KEY_ESCAPE
	ev.pressed = pulsada
	Input.parse_input_event(ev)

## Navegación real entre pantallas (change_scene_to_file de verdad).
## La sonda deja de ser la escena actual para que el cambio no la libere.
func _test_flujo() -> void:
	var res := PackedStringArray()

	var menu: Node = load(Routes.MENU).instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	await _frames(2)

	# 1) menú -> selector (botón Jugar)
	menu.get_node("%Jugar").pressed.emit()
	await _frames(5)
	res.append("menu_a_selector=" + str(_en_escena(Routes.SELECTOR)))

	# 2) selector -> juego (primera tarjeta desbloqueada)
	var tarjetas: Array = []
	var selector := get_tree().current_scene
	if selector != null:
		tarjetas = selector.get_node("%Lista").get_children()
	res.append("selector_con_tarjetas=" + str(not tarjetas.is_empty()))
	if not tarjetas.is_empty():
		(tarjetas[0] as Button).pressed.emit()
	await _frames(6)
	var juego := get_tree().current_scene
	res.append("selector_a_juego=" + str(_en_escena(Routes.JUEGO)))
	res.append("nivel_cargado=" + str(
		juego != null and juego.get_node_or_null("Level_01_Test") != null))

	# 3) juego -> menú (botón "Menú principal" de la pausa)
	var pausa: Node = null
	if juego != null:
		pausa = juego.get_node_or_null("PauseMenu")
	res.append("pausa_presente=" + str(pausa != null))
	if pausa != null:
		pausa.get_node("%Menu").pressed.emit()
		await _frames(5)
	res.append("juego_a_menu=" + str(_en_escena(Routes.MENU)))

	# 4) menú -> selector -> menú (botón Volver)
	var menu2 := get_tree().current_scene
	if menu2 != null:
		menu2.get_node("%Jugar").pressed.emit()
		await _frames(5)
	var selector2 := get_tree().current_scene
	if selector2 != null:
		selector2.get_node("%Volver").pressed.emit()
		await _frames(5)
	res.append("volver_al_menu=" + str(_en_escena(Routes.MENU)))

	# 5) menú -> selector -> juego -> selector (botón Continuar del banner)
	var menu3 := get_tree().current_scene
	if menu3 != null:
		menu3.get_node("%Jugar").pressed.emit()
		await _frames(5)
	var selector3 := get_tree().current_scene
	if selector3 != null:
		var primera: Array = selector3.get_node("%Lista").get_children()
		if not primera.is_empty():
			(primera[0] as Button).pressed.emit()
	await _frames(6)
	var juego2 := get_tree().current_scene
	var boton: Node = null
	if juego2 != null:
		boton = juego2.get_node_or_null("HUD/Root/Banner/Contenido/BannerContinue")
	res.append("boton_banner=" + str(boton != null))
	if boton != null:
		(boton as Button).pressed.emit()
		await _frames(5)
	res.append("banner_a_selector=" + str(_en_escena(Routes.SELECTOR)))

	# Limpieza: la sonda recupera su papel de escena actual.
	var ultima := get_tree().current_scene
	get_tree().current_scene = self
	if ultima != null and ultima != self:
		get_tree().root.remove_child(ultima)
		ultima.free()

	var fallos := 0
	for r in res:
		if r.ends_with("false"):
			fallos += 1
	print("PROBE flujo ", res, " fallos=", fallos)

func _en_escena(ruta: String) -> bool:
	var actual := get_tree().current_scene
	return actual != null and String(actual.scene_file_path) == ruta

# --- FASE 4 -----------------------------------------------------------------

## Buses, carga de los 13 ficheros, reproducción de efectos y música
## que debe seguir sonando con el árbol pausado.
func _test_audio() -> void:
	var buses := AudioServer.get_bus_index("Music") >= 0 \
		and AudioServer.get_bus_index("SFX") >= 0

	var faltan := 0
	for key in AudioManager.SFX:
		if not ResourceLoader.exists(AudioManager.SFX_DIR + String(AudioManager.SFX[key])):
			faltan += 1
	for key in AudioManager.MUSIC:
		if not ResourceLoader.exists(AudioManager.MUSIC_DIR + String(AudioManager.MUSIC[key])):
			faltan += 1

	AudioManager.play_sfx("jump")
	await _frames(2)
	var sfx_ok := _sfx_sonando()

	var musica := _reproductor_musica()
	var pista := musica.stream.resource_path.get_file() if musica != null else "?"
	var avanza_en_pausa := false
	if musica != null:
		var antes := musica.get_playback_position()
		get_tree().paused = true
		await _frames(8)
		avanza_en_pausa = musica.get_playback_position() > antes
		get_tree().paused = false

	print("PROBE audio buses=", buses,
		" ficheros_sfx=", AudioManager.SFX.size(),
		" ficheros_musica=", AudioManager.MUSIC.size(),
		" faltan=", faltan,
		" sfx_reproducido=", sfx_ok,
		" musica_pista=", pista,
		" musica_avanza_en_pausa=", avanza_en_pausa,
		" sin_pausa=", not get_tree().paused)

func _sfx_sonando() -> bool:
	for child in AudioManager.get_children():
		if child is AudioStreamPlayer and child.bus == "SFX" and child.playing:
			return true
	return false

func _reproductor_musica() -> AudioStreamPlayer:
	for child in AudioManager.get_children():
		if child is AudioStreamPlayer and child.bus == "Music" and child.playing:
			return child
	return null

# --- FASE 1 -----------------------------------------------------------------

func _check_camera() -> void:
	var offset: Vector3 = _camera.global_position - _player.global_position
	var forward: Vector3 = -_camera.global_transform.basis.z
	var to_player: Vector3 = (_player.global_position + Vector3(0, 1, 0)) - _camera.global_position
	var aligned := forward.dot(to_player.normalized())
	print("PROBE camara detras=", offset.z > 0.0, " arriba=", offset.y > 0.0,
		" apunta_al_personaje=", aligned > 0.9, " dist=", offset.length())

func _test_hud_inicial() -> void:
	if _hud == null:
		print("PROBE hud existe=false")
		return
	var corazones := 0
	for i in 3:
		var heart := _hud.get_node_or_null("Root/VidasPanel/LivesRow/Heart%d" % (i + 1)) as TextureRect
		if heart != null and heart.texture != null:
			corazones += 1
	var contador := _hud.get_node_or_null("Root/ColeccionablesPanel/Fila/Collectibles") as Label
	var texto := _hud.get_node_or_null("Root/ProgresoBox/ProgressText") as Label
	print("PROBE hud corazones=", corazones,
		" contador='", contador.text if contador else "?", "'",
		" progreso='", texto.text if texto else "?", "'")

func _reposo() -> void:
	print("PROBE reposo y=", _player.global_position.y, " en_suelo=", _player.is_on_floor())

func _test_movement() -> void:
	var antes: Vector3 = _player.global_position
	Input.action_press("move_forward")
	await _frames(60)
	var mientras: Vector3 = _player.global_position - antes
	Input.action_release("move_forward")
	await _frames(25)
	print("PROBE avanzar delta=", mientras, " avanzo=", mientras.z < -0.5,
		" frena=", Vector3(_player.velocity.x, 0, _player.velocity.z) == Vector3.ZERO)

	Input.action_press("move_right")
	await _frames(40)
	var lateral: Vector3 = _player.global_position - antes
	Input.action_release("move_right")
	await _frames(10)
	print("PROBE lateral x=", lateral.x, " desplazo_derecha=", lateral.x > 0.5)

func _test_jump() -> void:
	var y0: float = _player.global_position.y
	var pico := 0.0
	Input.action_press("jump")
	await _frames(3)
	var salto_suena := _sfx_sonando()
	await _frames(22)
	Input.action_release("jump")
	for i in 90:
		await get_tree().physics_frame
		pico = maxf(pico, _player.global_position.y - y0)
		if pico > 0.05 and _player.is_on_floor():
			break
	print("PROBE salto altura_pico=", pico, " supera_escalones_1m=", pico > 1.6,
		" en_suelo=", _player.is_on_floor(),
		" sonido=", salto_suena,
		" pos=", _player.global_position,
		" seguro=", _player.get("_safe_position"),
		" vidas=", GameState.lives)

func _test_fall() -> void:
	var vidas_antes := GameState.lives
	# Espera a que el jugador esté en el suelo: así la referencia es fiable.
	for i in 90:
		await get_tree().physics_frame
		if _player.is_on_floor():
			break
	var seguro: Vector3 = _player.global_position
	_player.global_position = Vector3(0, -100, 0)
	await _frames(6)
	var de_vuelta: bool = _player.global_position.distance_to(seguro) < 1.0
	print("PROBE abismo respawn=", de_vuelta, " vidas=", vidas_antes, "->", GameState.lives,
		" perdio_vida=", GameState.lives == vidas_antes - 1,
		" seguro=", seguro, " vuelta_en=", _player.global_position)

func _test_sin_salto_aereo() -> void:
	_player.velocity = Vector3.ZERO
	_player.global_position = Vector3(0, 6, 5)
	await _frames(20)
	var y0: float = _player.global_position.y
	Input.action_press("jump")
	await _frames(6)
	var delta: float = _player.global_position.y - y0
	Input.action_release("jump")
	print("PROBE sin_coyote delta=", delta, " no_salto=", delta < 0.5)
	await _frames(70)

func _test_doble_salto() -> void:
	_player.set("max_jumps", 2)
	_player.velocity = Vector3.ZERO
	_player.global_position = Vector3(0, 0.2, 22)
	await _frames(20)

	Input.action_press("jump")
	await _frames(6)
	Input.action_release("jump")
	await _frames(4)
	var velocidad_antes: float = _player.velocity.y

	Input.action_press("jump")
	await _frames(3)
	var velocidad_2: float = _player.velocity.y
	Input.action_release("jump")
	var restantes: int = _player.get("_jumps_left")

	print("PROBE doble_salto impulso_nuevo=", velocidad_2 > 5.0,
		" v_antes=", velocidad_antes, " v_2do=", velocidad_2, " restantes=", restantes)

	_player.set("max_jumps", 1)
	await _frames(110)

# --- FASE 2 -----------------------------------------------------------------

func _test_recoger_coleccionable() -> void:
	# Heart6 está sobre el segundo hueco: ninguna otra prueba lo recoge antes.
	var heart := _ruta("Collectibles/Heart6")
	if heart == null:
		var hijos := PackedStringArray()
		var col := get_node_or_null("/root/Probe/Main/Level_01_Test/Collectibles")
		if col != null:
			hijos = _nombres(col)
		print("PROBE coleccionable encontrado=false coleccionables=", hijos,
			" recogidos=", GameState.collectibles)
		return
	var antes := GameState.collectibles
	_player.velocity = Vector3.ZERO
	_player.global_position = Vector3(heart.global_position.x, 0.2, heart.global_position.z)
	await _frames(6)
	var recogido := GameState.collectibles == antes + 1
	var tomado := false
	if is_instance_valid(heart):
		tomado = heart.get("_taken") == true
	var desaparecio := not is_instance_valid(heart) or tomado
	print("PROBE coleccionable antes=", antes, " despues=", GameState.collectibles,
		" recogido=", recogido, " desaparece=", desaparecio)

func _test_caja_normal() -> void:
	var caja := _ruta("Crates/CrateNormal")
	if caja == null:
		print("PROBE caja_normal encontrada=false")
		return
	_player.velocity = Vector3.ZERO
	_player.global_position = caja.global_position + Vector3(1.0, -0.3, 0)
	await _frames(4)
	var dist := (_player.global_position + Vector3.UP * 0.9).distance_to(caja.global_position)
	var en_grupo := caja.is_in_group("hit_by_spin")
	await _girar()
	await _frames(3)
	var girando := _player.is_spinning()
	await _frames(27)
	print("PROBE caja_normal rota=", not is_instance_valid(caja),
		" dist=", dist, " en_grupo=", en_grupo, " girando=", girando)

func _test_caja_con_contenido() -> void:
	var caja := _ruta("Crates/CrateContentsFloor1")
	if caja == null:
		print("PROBE caja_contenido encontrada=false")
		return
	var antes := GameState.collectibles
	var en_antes := get_tree().get_nodes_in_group("collectibles").size()
	_player.velocity = Vector3.ZERO
	_player.global_position = caja.global_position + Vector3(1.0, -0.3, 0)
	await _frames(4)
	var dist := (_player.global_position + Vector3.UP * 0.9).distance_to(caja.global_position)
	var en_grupo := caja.is_in_group("hit_by_spin")
	var rota_antes: bool = caja.get("_broken")
	await _girar()
	await _frames(3)
	var girando := _player.is_spinning()
	await _frames(27)
	var despues := GameState.collectibles
	var en_tras := get_tree().get_nodes_in_group("collectibles").size()
	# Suelta confirmada si aumenta el grupo (suelta en el suelo) o el contador
	# (suelta recogida al instante por el jugador, que está pegado a la caja).
	var solto := en_tras > en_antes or despues > antes
	print("PROBE caja_contenido rota=", not is_instance_valid(caja),
		" solto_coleccionables=", solto, " total=", antes, "->", despues,
		" grupo=", en_antes, "->", en_tras,
		" dist=", dist, " en_grupo=", en_grupo, " rota_antes=", rota_antes,
		" girando=", girando)

## La caja BONUS debe devolver una vida al romperse.
func _test_caja_bonus() -> void:
	var caja := _ruta("Crates/CrateBonus")
	if caja == null:
		print("PROBE caja_bonus encontrada=false")
		return
	# Gasta una vida antes de romperla para poder medir la recuperación.
	GameState.take_life()
	var vidas_antes := GameState.lives
	_player.velocity = Vector3.ZERO
	_player.global_position = caja.global_position + Vector3(-1.0, -0.3, 0)
	await _frames(4)
	await _girar()
	await _frames(30)
	print("PROBE caja_bonus rota=", not is_instance_valid(caja),
		" vidas=", vidas_antes, "->", GameState.lives,
		" recupero=", GameState.lives == vidas_antes + 1)

func _test_enemigo_dania() -> void:
	var enemigo := _ruta("Enemies/Enemy1")
	if enemigo == null:
		print("PROBE enemigo encontrado=false")
		return
	GameState.start_level("level_01")
	_player.velocity = Vector3.ZERO
	_player.global_position = enemigo.global_position + Vector3(1.0, -0.05, 0)
	await _frames(6)
	var tras_golpe := GameState.lives

	# Segundo contacto inmediato: la invulnerabilidad debe proteger.
	_player.velocity = Vector3.ZERO
	_player.global_position = enemigo.global_position + Vector3(1.0, -0.05, 0)
	await _frames(4)
	print("PROBE enemigo_dania vidas 3->", tras_golpe, " bajo=", tras_golpe == 2,
		" invulnerable=", GameState.lives == tras_golpe)
	GameState.start_level("level_01")

func _test_enemigo_derrotado() -> void:
	var enemigo := _ruta("Enemies/Enemy2")
	if enemigo == null:
		print("PROBE enemigo2 encontrado=false")
		return
	# El ataque se prepara antes de colocarse: si no, el enfriamiento lo bloquea.
	await _esperar_ataque_listo()
	_player.velocity = Vector3.ZERO
	_player.global_position = enemigo.global_position + Vector3(1.6, -0.05, 0)
	await _frames(2)
	var dist := (_player.global_position + Vector3.UP * 0.9).distance_to(enemigo.global_position)
	await _pulsar_ataque()
	await _frames(40)
	print("PROBE enemigo_derrotado=", not is_instance_valid(enemigo), " dist=", dist)
	GameState.start_level("level_01")

func _test_checkpoint() -> void:
	var cp := _ruta("Checkpoint1")
	if cp == null:
		print("PROBE checkpoint encontrado=false")
		return
	_player.velocity = Vector3.ZERO
	_player.global_position = Vector3(cp.global_position.x, 0.2, cp.global_position.z)
	await _frames(6)
	var sitio: Vector3 = cp.global_position
	var activado: bool = cp.get("_activated")
	# Espera a que el jugador se asiente: así el punto seguro es el checkpoint.
	for i in 60:
		await get_tree().physics_frame
		if _player.is_on_floor():
			break
	var guardado: Vector3 = _player.get("_safe_position")

	_player.global_position = Vector3(0, -100, 0)
	await _frames(6)
	var volvio: Vector3 = _player.global_position
	print("PROBE checkpoint activado=", activado,
		" sitio=", sitio, " guardado=", guardado,
		" guardado_cerca=", guardado.distance_to(sitio) < 2.0,
		" respawn_cerca=", volvio.distance_to(sitio) < 2.0)

func _test_fin_de_nivel() -> void:
	var fin := _ruta("LevelEnd")
	if fin == null:
		print("PROBE fin_nivel encontrado=false")
		return
	_player.velocity = Vector3.ZERO
	_player.global_position = Vector3(fin.global_position.x, 0.2, fin.global_position.z)
	await _frames(6)
	var banner_oculto := true
	var boton_ok := false
	if _hud != null:
		var banner := _hud.get_node_or_null("Root/Banner")
		if banner != null:
			banner_oculto = banner.visible
		var boton := _hud.get_node_or_null("Root/Banner/Contenido/BannerContinue") as Button
		boton_ok = boton != null and boton.pressed.get_connections().size() > 0
	print("PROBE fin_nivel completado=", _nivel_completado,
		" progreso=", GameState.progress, " banner_visible=", banner_oculto,
		" boton_continuar=", boton_ok,
		" guardado=", GameState.completed_levels.get("level_01", -1))

# --- utilidades -------------------------------------------------------------

## Espera a que el ataque giratorio esté disponible (animación + enfriamiento).
func _esperar_ataque_listo() -> void:
	for i in 90:
		if not _player.is_spinning() and float(_player.get("_attack_ready")) <= 0.0:
			break
		await get_tree().physics_frame

## Simula la pulsación de la tecla de ataque (mantenida unos frames, como
## haría una tecla real, para que el jugador la lea con seguridad).
func _pulsar_ataque() -> void:
	var listo := float(_player.get("_attack_ready"))
	Input.action_press("attack")
	await _frames(3)
	var girando := _player.is_spinning()
	var sonido := _sfx_sonando()
	Input.action_release("attack")
	print("PROBE ataque listo_antes=", listo, " girando=", girando, " sonido=", sonido)

## Espera a que esté disponible y luego activa el giro.
func _girar() -> void:
	await _esperar_ataque_listo()
	await _pulsar_ataque()

func _capturar_frame(destino := "C:/Users/ferney.naranjo/AppData/Local/Temp/opencode/f1_frame.png") -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var imagen := get_viewport().get_texture().get_image()
	imagen.save_png(destino)
	print("PROBE fotograma guardado=", imagen.get_size(), " archivo=", destino.get_file())

func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	for child in node.get_children():
		var found := _find_camera(child)
		if found != null:
			return found
	return null
