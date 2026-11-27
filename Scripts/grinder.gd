extends StaticBody3D
# Maszynka do mięsa: truchła z torby albo szczur z ręki. Jeden szczur to jedna porcja,
# wielki szczur daje ich więcej.

signal meat_ground(portions: int)

const Sfx = preload("res://Scripts/sfx.gd")
const Qte = preload("res://Scripts/qte.gd")
const BIG_PORTIONS := 3 # porcje z wielkiego szczura
const GRIND_TIME := 2.5
const SHAKES := 20
const JAM_CHANCE := 0.25 # szansa, że przy mieleniu się zatnie
const JAM_KEYS := 4
const JAM_KEY_TIME := 1.0

var _busy := false
var _jammed := 0 # tyle porcji utknęło w zaciętej maszynce

@onready var model: Node3D = $model
@onready var bubble: Label3D = $Bubble

func get_prompt(player) -> String:
	if _busy:
		return "Maszynka mieli..."
	if _jammed:
		return "[E] Odetkaj maszynkę"
	if _has_rat(player):
		return "[E] Wrzuć szczura do maszynki"
	var portions := _bag_portions(player)
	if portions > 0:
		return "Masz zajęte ręce" if player.held else "[E] Zmiel truchła (porcje: %d)" % portions
	return "Maszynka: potrzebne szczury"

func interact(player) -> void:
	if _busy:
		return
	if _jammed:
		_unclog(player)
		return
	var portions := 0
	if _has_rat(player):
		player.discard()
		portions = 1
	elif not player.held and _bag_portions(player) > 0:
		portions = _bag_portions(player)
		player.add_carcasses(-player.carcasses)
		player.add_big_carcasses(-player.big_carcasses)
	else:
		return
	Sfx.play_at(self, "squeak")
	_grind(portions, randf() < JAM_CHANCE)

# "jams": w połowie się zatnie i trzeba ją odetkać.
func _grind(portions: int, jams: bool) -> void:
	_busy = true
	Sfx.play_at(self, "grind")
	bubble.text = "PIIISK!"
	var shakes := int(SHAKES / 2.0) if jams else SHAKES
	var tween := create_tween()
	for i in shakes:
		if i == 6:
			tween.tween_callback(bubble.set_text.bind("BRRRUM... CHRUP"))
		tween.tween_property(model, "rotation:x", 0.09 if i % 2 == 0 else -0.09, GRIND_TIME / SHAKES)
	if jams:
		tween.tween_callback(_jam.bind(portions))
		return
	tween.tween_callback(_finish.bind(portions))
	tween.tween_interval(1.5)
	tween.tween_callback(bubble.set_text.bind(""))

func _jam(portions: int) -> void:
	model.rotation.x = 0.0
	_busy = false
	_jammed = portions
	bubble.text = "ZGRZYT! Zacięła się!"
	Sfx.play_at(self, "angry")

func _unclog(player) -> void:
	player.set_busy(true)
	var qte := Qte.new()
	add_child(qte)
	qte.done.connect(func(success: bool):
		player.set_busy(false)
		if success:
			var portions := _jammed
			_jammed = 0
			_grind(portions, false)
		else:
			bubble.text = "Nadal zacięta!")
	qte.start("Odetkaj maszynkę!", JAM_KEYS, JAM_KEY_TIME)

func _bag_portions(player) -> int:
	return player.carcasses + player.big_carcasses * BIG_PORTIONS

func _has_rat(player) -> bool:
	return player.held != null and player.held.is_in_group("rat")

func _finish(portions: int) -> void:
	model.rotation.x = 0.0
	bubble.text = "DING! Porcje: +%d" % portions
	_busy = false
	Sfx.play_at(self, "ding")
	meat_ground.emit(portions)
