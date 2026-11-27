extends StaticBody3D
# Maszynka do mięsa: truchła z torby albo szczur z ręki, jeden szczur to jedna porcja.

signal meat_ground(portions: int)

const Sfx = preload("res://Scripts/sfx.gd")
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
	if player.carcasses > 0:
		return "Masz zajęte ręce" if player.held else "[E] Zmiel truchła (%d)" % player.carcasses
	return "Maszynka: potrzebne szczury"

func interact(player) -> void:
	if _busy:
		return
	var portions := 0
	if _has_rat(player):
		player.discard()
		portions = 1
	elif not player.held and player.carcasses > 0:
		portions = player.carcasses
		player.add_carcasses(-portions)
	else:
		return
	_busy = true
	Sfx.play_at(self, "squeak")
	Sfx.play_at(self, "grind")
	bubble.text = "PIIISK!"
	var tween := create_tween()
	for i in SHAKES:
		if i == 6:
			tween.tween_callback(bubble.set_text.bind("BRRRUM... CHRUP"))
		tween.tween_property(model, "rotation:x", 0.09 if i % 2 == 0 else -0.09, GRIND_TIME / SHAKES)
	tween.tween_callback(_finish.bind(portions))
	tween.tween_interval(1.5)
	tween.tween_callback(bubble.set_text.bind(""))

func _has_rat(player) -> bool:
	return player.held != null and player.held.is_in_group("rat")

func _finish(portions: int) -> void:
	model.rotation.x = 0.0
	bubble.text = "DING! Porcje: +%d" % portions
	_busy = false
	Sfx.play_at(self, "ding")
	meat_ground.emit(portions)
