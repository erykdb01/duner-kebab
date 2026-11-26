extends "res://Scripts/item.gd"
# Gotowy kebab. "contents" to warstwy od dołu (bez pierwszej tortilli).

const NAMES := {
	&"meat": "mięso", &"salad": "surówka", &"sauce": "sos",
	&"tortilla": "tortilla", &"rat": "SZCZUR",
}
const FILLING_Y := 0.19
const LAYER_STEP := 0.018

var contents: Array[StringName] = []

static func describe(ingredients: Array[StringName], separator := ", ") -> String:
	var listed: Array[String] = []
	for id in ingredients:
		listed.append(NAMES[id])
	return separator.join(listed)

# Wywołać raz, po dodaniu do sceny.
func setup(ingredients: Array[StringName]) -> void:
	contents = ingredients
	# Każda dodatkowa tortilla pogrubia zawijkę.
	var width := 1.0 + 0.08 * contents.count(&"tortilla")
	$wrap.scale = Vector3(width, 1.0, width)
	$sauce.scale = Vector3(width, 1.0, width)
	$sauce.visible = &"sauce" in contents

	# $meat, $salad i $rat to ukryte wzory, kopiowane w kolejności składników.
	for template in [$meat, $salad, $rat]:
		template.visible = false
	var height := FILLING_Y
	for i in contents.size():
		var id := contents[i]
		if id == &"sauce" or id == &"tortilla":
			continue
		var layer: Node3D = get_node(NodePath(id)).duplicate()
		layer.visible = true
		layer.position.y = height + (0.04 if id == &"rat" else 0.0)
		layer.rotate_y(i * 1.3)
		add_child(layer)
		height += LAYER_STEP

	item_name = "Kebab (%s)" % (describe(contents) if contents else "pusty")
