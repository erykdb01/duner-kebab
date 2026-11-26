extends StaticBody3D
# Maszynka do mięsa: wchodzi szczur, wychodzą porcje. Bez szczegółów.

signal meat_ground(portions: int)

const PORTIONS := 3
const GRIND_TIME := 2.5
const SHAKES := 20

var _busy := false

@onready var model: Node3D = $model
@onready var bubble: Label3D = $Bubble

func get_prompt(player) -> String:
	if _busy:
		return "Maszynka mieli..."
	if _has_rat(player):
		return "[E] Wrzuć szczura do maszynki"
	return "Maszynka: potrzebny szczur"

func interact(player) -> void:
	if _busy or not _has_rat(player):
		return
	player.discard()
	_busy = true
	bubble.text = "PIIISK!"
	var tween := create_tween()
	for i in SHAKES:
		if i == 6:
			tween.tween_callback(bubble.set_text.bind("BRRRUM... CHRUP"))
		tween.tween_property(model, "rotation:x", 0.09 if i % 2 == 0 else -0.09, GRIND_TIME / SHAKES)
	tween.tween_callback(_finish)
	tween.tween_interval(1.5)
	tween.tween_callback(bubble.set_text.bind(""))

func _has_rat(player) -> bool:
	return player.held != null and player.held.is_in_group("rat")

func _finish() -> void:
	model.rotation.x = 0.0
	bubble.text = "DING! +%d porcje" % PORTIONS
	_busy = false
	meat_ground.emit(PORTIONS)
