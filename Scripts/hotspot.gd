extends Area3D
# Niewidzialne miejsce pod [E]: właz, drabina, gniazdo szczurów. Co robi, mówi twórca.

var prompt: Callable # (player) -> String
var action: Callable # (player)

func get_prompt(player) -> String:
	return prompt.call(player)

func interact(player) -> void:
	action.call(player)

# "size" to wymiary pudełka celownika, "pos" jego środek.
func setup(pos: Vector3, size: Vector3, new_prompt: Callable, new_action: Callable) -> void:
	position = pos
	prompt = new_prompt
	action = new_action
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	add_child(shape)
