extends RefCounted
# Teksty i imiona z pliku Data/dialogi.json (opis: Data/JAK_EDYTOWAC.md).

const PATH := "res://Data/dialogi.json"

static var _data := {}

# Wczytuje plik od nowa (na początku każdej nocy).
static func reload() -> void:
	_data = {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(PATH)) != OK:
		push_error("dialogi.json, linia %d: %s" % [
			json.get_error_line() + 1, json.get_error_message()])
	elif json.data is Dictionary:
		_data = json.data

static func section(name: String) -> Dictionary:
	if _data.is_empty():
		reload()
	return _data.get(name, {})

static func character(id: String) -> Dictionary:
	return section("postacie").get(id, {})

# Postacie pasujące do rodzaju klienta.
static func characters_of(type_id: String) -> Array:
	return section("postacie").keys().filter(
		func(id): return character(id).get("typ", "") == type_id)

static func names(gender: String) -> Array:
	return section("imiona").get(gender, [])

# Losowy tekst postaci; gdy go nie ma, domyślny.
static func line(id: String, key: String, values := {}) -> String:
	var entry = character(id).get(key, section("domyslne").get(key, "..."))
	return _pick(entry).format(values)

static func player_line(key: String) -> String:
	return _pick(section("gracz").get(key, "..."))

static func ingredient(key: String) -> String:
	return str(section("skladniki").get(key, key))

# Rozmowy postaci (najpierw własne), potem wspólne.
static func conversations(id: String, with_common: bool) -> Array:
	var own: Array = character(id).get("rozmowy", []).duplicate()
	own.shuffle()
	if with_common:
		var common: Array = section("domyslne").get("rozmowy", []).duplicate()
		common.shuffle()
		own.append_array(common)
	return own

static func _pick(entry) -> String:
	if entry is Array:
		return str(entry.pick_random()) if entry else "..."
	return str(entry)
