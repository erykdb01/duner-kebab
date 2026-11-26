extends Area3D
# Pudełko z zapasowymi bezpiecznikami na ścianie w kuchni.

const B = preload("res://Scripts/build.gd")
const Fuse = preload("res://Objects/fuse.tscn")

func _ready() -> void:
	B.box(self, Vector3(0, -0.1, 0), Vector3(0.24, 0.03, 0.48), B.mat("deski", Color.WHITE, 2.0))
	B.box(self, Vector3(0, -0.02, 0), Vector3(0.18, 0.13, 0.36), B.mat("metal_czerwony", Color.WHITE, 3.0))
	for i in 3:
		B.cyl(self, Vector3(0, 0.08, -0.1 + i * 0.1), 0.03, 0.08, B.mat("plastik_kremowy", Color.WHITE, 5.0))
	# Pomarańczowa kontrolka świeci też po ciemku.
	B.box(self, Vector3(0.095, -0.02, 0), Vector3(0.008, 0.035, 0.09), B.glow(Color(1, 0.6, 0.1)))

func get_prompt(player) -> String:
	if player.held:
		return "Masz zajęte ręce"
	return "[E] Weź zapasowy bezpiecznik"

func interact(player) -> void:
	if player.held:
		return
	var fuse = Fuse.instantiate()
	add_child(fuse)
	player.hold(fuse)
