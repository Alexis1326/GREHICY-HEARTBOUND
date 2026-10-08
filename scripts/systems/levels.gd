class_name Levels
extends RefCounted

## Catálogo de niveles, leído de data/levels.json y cacheado.
## Añadir un mundo nuevo es editar el JSON: el selector se construye solo.

const RUTA := "res://data/levels.json"

static var _cache: Array[Dictionary] = []
static var _loaded := false

## Devuelve todos los niveles en el orden del fichero.
static func all() -> Array[Dictionary]:
	if not _loaded:
		_loaded = true
		var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
		if datos is Array:
			for item in datos:
				if item is Dictionary:
					_cache.append(item)
	return _cache

## Posición del nivel en el catálogo (-1 si no existe).
static func index_of(id: String) -> int:
	var niveles := all()
	for i in niveles.size():
		if String(niveles[i].get("id", "")) == id:
			return i
	return -1

static func by_id(id: String) -> Dictionary:
	var idx := index_of(id)
	return all()[idx] if idx >= 0 else {}

## Escena del nivel ("" si no existe).
static func scene_path(id: String) -> String:
	return String(by_id(id).get("escena", ""))

## Nivel anterior en el catálogo ("" si es el primero o no existe).
static func previous_id(id: String) -> String:
	var idx := index_of(id)
	if idx <= 0:
		return ""
	return String(all()[idx - 1].get("id", ""))
