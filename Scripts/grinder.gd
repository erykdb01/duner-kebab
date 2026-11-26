extends StaticBody3D
# Maszynka do mięsa: wchodzi szczur, wychodzą porcje. Bez szczegółów.

signal meat_ground(portions: int)
signal gold_found
signal started

const Sfx = preload("res://Scripts/sfx.gd")
const Night = preload("res://Scripts/night.gd")
const PORTIONS := 3
const GRIND_TIME := 2.5
const SHAKES := 20

var _busy := false
var _golden := false

@onready var model: Node3D = $model
@onready var bubble: Label3D = $Bubble

func get_prompt(player) -> String:
	if _busy:
		return "Maszynka mieli..."
	if Night.dark:
		return "Maszynka stoi: nie ma prądu"
	if _has_rat(player):
		return "[E] Wrzuć szczura do maszynki"
	return "Maszynka: potrzebny szczur"

func interact(player) -> void:
	if _busy or Night.dark or not _has_rat(player):
		return
	_golden = player.held.is_in_group("zloty")
	player.discard()
	_busy = true
	Sfx.play_at(self, "squeak")
	Sfx.play_at(self, "grind")
	bubble.text = "PIIISK!"
	var tween := create_tween()
	for i in SHAKES:
		if i == 6:
			tween.tween_callback(bubble.set_text.bind("BRRRUM... CHRUP"))
		tween.tween_property(model, "rotation:x", 0.09 if i % 2 == 0 else -0.09, GRIND_TIME / SHAKES)
	tween.tween_callback(_finish)
	tween.tween_interval(1.5)
	tween.tween_callback(bubble.set_text.bind(""))
	started.emit()

func _has_rat(player) -> bool:
	return player.held != null and player.held.is_in_group("rat")

func _finish() -> void:
	model.rotation.x = 0.0
	bubble.text = "DING! +%d porcje" % PORTIONS
	_busy = false
	Sfx.play_at(self, "ding")
	meat_ground.emit(PORTIONS)
	if _golden:
		gold_found.emit()
