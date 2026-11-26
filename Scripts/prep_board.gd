extends Area3D
# Deska: najpierw tortilla, potem dowolne warstwy, na końcu zawinięcie w kebaba.

const Kebab = preload("res://Objects/kebab.tscn")
const KebabScript = preload("res://Scripts/kebab.gd")
const Sfx = preload("res://Scripts/sfx.gd")
const MAX_LAYERS := 10
const FIRST_LAYER_Y := 0.038
const LAYER_HEIGHTS := {
	&"tortilla": 0.014, &"meat": 0.036, &"salad": 0.034, &"sauce": 0.012, &"rat": 0.1,
}
const ADD_PROMPTS := {
	&"tortilla": "Dołóż tortillę",
	&"meat": "Dodaj mięso",
	&"salad": "Dodaj surówkę",
	&"sauce": "Dodaj sos",
}

var has_tortilla := false
var contents: Array[StringName] = [] # warstwy od dołu
var _layers: Array[Node3D] = []

func _ready() -> void:
	_refresh()

# Prompt i akcja dla pojemników ze składnikami.
func add_prompt(ingredient: StringName, player) -> String:
	var problem := _problem(ingredient, player)
	return problem if problem else "[E] " + ADD_PROMPTS[ingredient]

func add(ingredient: StringName, player) -> bool:
	if _problem(ingredient, player):
		return false
	if ingredient == &"tortilla" and not has_tortilla:
		has_tortilla = true
	else:
		contents.append(ingredient)
	_refresh()
	Sfx.play_at(self, "plop")
	return true

func get_prompt(player) -> String:
	if player.held and not player.held.is_in_group("rat"):
		return "Masz zajęte ręce"
	if not has_tortilla:
		return "Deska: najpierw tortilla"
	if player.held:
		return "[E] Włóż szczura do kebaba" if contents.size() < MAX_LAYERS else "Więcej się nie zmieści"
	if contents.is_empty():
		return "[E] Zawiń kebaba"
	return "[E] Zawiń kebaba\nOd dołu: " + KebabScript.describe(contents)

func interact(player) -> void:
	if not has_tortilla:
		return
	if player.held:
		if player.held.is_in_group("rat") and contents.size() < MAX_LAYERS:
			player.discard()
			contents.append(&"rat")
			_refresh()
			Sfx.play_at(self, "squeak")
		return
	var kebab = Kebab.instantiate()
	add_child(kebab)
	kebab.setup(contents.duplicate())
	player.hold(kebab)
	Sfx.play_at(self, "wrap")
	has_tortilla = false
	contents.clear()
	_refresh()

func _problem(ingredient: StringName, player) -> String:
	if player.held:
		return "Masz zajęte ręce"
	if not has_tortilla:
		return "" if ingredient == &"tortilla" else "Najpierw połóż tortillę"
	return "Więcej się nie zmieści" if contents.size() >= MAX_LAYERS else ""

# Węzły tortilla/meat/salad/sauce/rat to wzory; warstwy są ich kopiami.
func _refresh() -> void:
	$tortilla.visible = has_tortilla
	for layer in _layers:
		layer.queue_free()
	_layers.clear()
	var height := FIRST_LAYER_Y
	for i in contents.size():
		var id := contents[i]
		var layer: Node3D = get_node(NodePath(id)).duplicate()
		layer.visible = true
		layer.position = Vector3(0, height + (0.07 if id == &"rat" else 0.0), 0)
		layer.rotate_y(i * 0.7)
		add_child(layer)
		_layers.append(layer)
		height += LAYER_HEIGHTS[id]
