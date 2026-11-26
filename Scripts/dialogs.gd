extends RefCounted
# Teksty i imiona z pliku Data/dialogi.json (opis: Data/JAK_EDYTOWAC.md).

const PATH := "res://Data/dialogi.json"

static var _data := {}
static var _heard := {} # rozmowy, które już padły tej nocy

# Wczytuje plik od nowa (na początku każdej nocy).
static func reload() -> void:
	_data = {}
	_heard = {}
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
	var texts = character(id).get(key, section("domyslne").get(key, "..."))
	return _pick(texts).format(values)

# Powitanie: {"klient": ...} i ewentualnie "co" oraz "odpowiedzi".
static func greeting(id: String) -> Dictionary:
	var list = character(id).get("powitania", section("domyslne").get("powitania", []))
	if list is Array and list:
		list = list.pick_random()
	if list is Dictionary:
		return list
	return {"klient": str(list) if list is String else "..."}

static func player_line(key: String) -> String:
	return _pick(section("gracz").get(key, "..."))

static func ingredient(key: String) -> String:
	return str(section("skladniki").get(key, key))

# Rozmowy postaci na przemian ze wspólnymi (zaczyna się od własnej).
static func conversations(id: String, with_common: bool) -> Array:
	var own := _shuffled(character(id).get("rozmowy", []))
	var common: Array = []
	if with_common:
		common = _shuffled(section("domyslne").get("rozmowy", []))
	var mixed := []
	for i in maxi(own.size(), common.size()):
		if i < own.size():
			mixed.append(own[i])
		if i < common.size():
			mixed.append(common[i])
	return mixed

# Zabiera z listy pierwszą rozmowę, której tej nocy jeszcze nie było.
static func take(list: Array) -> Dictionary:
	var index := 0
	for i in list.size():
		if not _heard.has(list[i].get("klient", "")):
			index = i
			break
	var talk: Dictionary = list.pop_at(index)
	_heard[talk.get("klient", "")] = true
	return talk

static func _shuffled(list: Array) -> Array:
	var copy := list.duplicate()
	copy.shuffle()
	return copy

static func _pick(entry) -> String:
	if entry is Array:
		return str(entry.pick_random()) if entry else "..."
	return str(entry)
