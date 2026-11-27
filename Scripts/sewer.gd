extends Node3D
# Kanały pod altaną śmietnikową: właz na podwórku, tunel z gniazdami szczurów, nóż w ręce
# i wejścia w walkę (battle.gd). Tunel leży daleko od lokalu; gracz jest tam przenoszony.
# Gra na górze toczy się dalej.

signal message(text: String)
signal gold_taken
signal pimpek_killed

const B = preload("res://Scripts/build.gd")
const Battle = preload("res://Scripts/battle.gd")
const Hotspot = preload("res://Scripts/hotspot.gd")
const Sfx = preload("res://Scripts/sfx.gd")
const MANHOLE := Vector3(-5.0, 0, 11.2) # w altanie, przed kontenerem
const YARD_SPOT := Vector3(-4.6, 0.05, 10.2) # tu stajesz po wyjściu
const ENTRY := Vector3(0, 0.05, 1.7)
const LENGTH := 24.0
const WIDTH := 4.0
const HEIGHT := 3.0
const NESTS: Array[Vector3] = [Vector3(-1.2, 0, 6), Vector3(1.2, 0, 11), Vector3(-1.2, 0, 16),
	Vector3(1.2, 0, 20), Vector3(0, 0, 22.8)]
const MAX_GROUP := 3
const RESPAWN_TIME := 40.0 # po tylu sekundach w pustym gnieździe są nowe szczury
const FAT_CHANCE := 0.2
const BIG_CHANCE := 0.12 # zamiast grupy w gnieździe siedzi jeden wielki szczur
const DEFEAT_HP := 3 # tyle zdrowia zostaje po pogryzieniu przez szczury
const FRAME_TIME := 0.25
const FIGHT_DISTANCE := 2.4 # tyle przed gniazdem staje gracz na czas walki
const FIGHT_PITCH := -0.35 # i tak pochyla widok (radiany)
const KNIFE_REST := Vector3(0.24, -0.22, -0.45)
const KNIFE_FIGHT := Vector3(0.28, -0.12, -0.5)

var occupied := false # gracz jest w kanałach
var gold_chance := 0.0 # szansa na złotego szczura w nowej grupie (ustawia game.gd)
var pimpek_free := false # Pimpek siedzi w którymś gnieździe (ustawia game.gd)
var _player # player.gd
var _battle := Battle.new()
var _knife := Node3D.new()
var _tunnel := Node3D.new() # wszystko, co widać na dole
var _nests: Array[Dictionary] = []
var _fighting := {} # gniazdo, z którym trwa walka
# Zdrowie na całą noc (nowa noc = przeładowana scena). Leczy tylko kebab z żywym szczurem.
var hp := Battle.MAX_HP
var _trip_loot: Array[StringName] = [] # szczury ubite w tym zejściu
var _torch_before := false
var _time := 0.0

func _ready() -> void:
	_build_tunnel()
	_build_manhole()
	add_child(_battle)
	_battle.killed.connect(_on_killed)
	_battle.bagged.connect(_on_bagged)
	_battle.finished.connect(_on_finished)

# Wywołać raz na początku nocy.
func setup(player) -> void:
	_player = player
	_build_knife()
	for at in NESTS:
		_add_nest(at)
	if pimpek_free:
		# Nie zajmuje gniazda ze złotym szczurem.
		var nest: Dictionary = _nests.filter(
			func(other): return not &"zloty" in other["rats"]).pick_random()
		var rats: Array[StringName] = [&"pimpek"]
		nest["rats"] = rats
		_show_nest(nest)

func heal(amount: int) -> void:
	hp = mini(hp + amount, Battle.MAX_HP)

# Koniec nocy: walka przepada, zdobyte truchła zostają.
func abort() -> void:
	_battle.abort()
	_fighting = {}

func _process(delta: float) -> void:
	_time += delta
	var frame := int(_time / FRAME_TIME) % 2
	for nest in _nests:
		if occupied:
			for rat in nest["sprites"]:
				rat.texture = rat.get_meta("frames")[frame]
		if nest["rats"].is_empty():
			nest["wait"] -= delta
			if nest["wait"] <= 0.0:
				_fill(nest)

# --- Wejście i wyjście ---

func _enter_prompt(player) -> String:
	if player.held:
		return "Właz do kanałów: potrzebne wolne ręce"
	return "[E] Zejdź do kanałów"

func _enter(player) -> void:
	if player.held:
		return
	occupied = true
	_tunnel.visible = true
	_trip_loot.clear()
	_torch_before = player.torch.visible
	player.torch.visible = true
	_knife.visible = true
	_move_player(to_global(ENTRY), PI)
	Sfx.play(player, "switch")

func _leave() -> void:
	occupied = false
	_tunnel.visible = false
	_player.torch.visible = _torch_before
	_knife.visible = false
	_move_player(YARD_SPOT, 0.0)
	Sfx.play(_player, "switch")

func _move_player(at: Vector3, yaw: float) -> void:
	_player.velocity = Vector3.ZERO
	_player.global_position = at
	_player.rotation.y = yaw
	_player.cam.rotation.x = 0.0

# --- Gniazda i walka ---

func _add_nest(at: Vector3) -> void:
	var spot := Hotspot.new()
	var nest := {"spot": spot, "rats": [], "sprites": [], "wait": 0.0}
	spot.setup(at + Vector3(0, 0.45, 0), Vector3(1.5, 0.9, 1.3),
		_nest_prompt.bind(nest), _fight.bind(nest))
	add_child(spot)
	B.ball(_tunnel, at + Vector3(0, 0.05, 0), Vector3(1.1, 0.22, 0.9),
		B.mat("karton", Color(0.6, 0.55, 0.5), 3.0))
	_nests.append(nest)
	_fill(nest)

func _fill(nest: Dictionary) -> void:
	var rats: Array[StringName] = []
	for i in randi_range(1, MAX_GROUP):
		rats.append(&"tlusty" if randf() < FAT_CHANCE else &"zwykly")
	if randf() < BIG_CHANCE:
		rats = [&"wielki"]
	elif randf() < gold_chance:
		gold_chance = 0.0
		rats[-1] = &"zloty"
		message.emit("W kanałach coś błysnęło na złoto...")
	nest["rats"] = rats
	_show_nest(nest)

# Sprite'y w gnieździe odpowiadają szczurom, które w nim zostały.
func _show_nest(nest: Dictionary) -> void:
	for sprite in nest["sprites"]:
		sprite.queue_free()
	nest["sprites"] = []
	var rats: Array = nest["rats"]
	var center: Vector3 = nest["spot"].position
	for i in rats.size():
		var kind: Dictionary = Battle.KINDS[rats[i]]
		var sprite := Sprite3D.new()
		var frames := [
			load("res://Textures/szczury/%s_0.png" % kind["texture"]),
			load("res://Textures/szczury/%s_1.png" % kind["texture"])]
		sprite.set_meta("frames", frames)
		sprite.texture = frames[0]
		sprite.pixel_size = 0.012 * kind["size"]
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.modulate = Color(0.75, 0.75, 0.7) * kind["tint"]
		sprite.flip_h = i % 2 == 1
		sprite.position = Vector3(center.x + (i - (rats.size() - 1) / 2.0) * 0.45,
			0.22 + 0.03 * i, center.z + (i % 2) * 0.3)
		_tunnel.add_child(sprite)
		nest["sprites"].append(sprite)
	nest["spot"].collision_layer = 2 if rats else 0

func _nest_prompt(_who, nest: Dictionary) -> String:
	if &"pimpek" in nest["rats"]:
		return "[E] Szczur z czerwoną kokardką\n(walka albo worek)"
	if &"wielki" in nest["rats"]:
		return "[E] Zaatakuj WIELKIEGO szczura"
	return "[E] Zaatakuj (szczury: %d)" % nest["rats"].size()

func _fight(_who, nest: Dictionary) -> void:
	_fighting = nest
	_player.set_busy(true)
	_battle.bag_free = _player.sack == &""
	# Gracz staje przodem do gniazda; walczący szczur pojawia się nad nim (battle.gd).
	var spot: Vector3 = nest["spot"].global_position
	var foot := Vector3(spot.x, 0.1, spot.z)
	_move_player(Vector3(foot.x, ENTRY.y, foot.z - FIGHT_DISTANCE), PI)
	_player.cam.rotation.x = FIGHT_PITCH
	for sprite in nest["sprites"]:
		sprite.hide()
	_knife.position = KNIFE_FIGHT
	_battle.knife = _knife
	_battle.start(nest["rats"], hp, foot)

func _on_killed(kind: StringName) -> void:
	_fighting["rats"].erase(kind)
	_trip_loot.append(kind)
	_add_loot(kind, 1)
	if kind == &"zloty":
		gold_taken.emit()
	elif kind == &"pimpek":
		pimpek_killed.emit()

func _add_loot(kind: StringName, count: int) -> void:
	if kind == &"wielki":
		_player.add_big_carcasses(count)
	else:
		_player.add_carcasses(count)

# Żywy szczur ląduje w worku gracza (złoty i tak oddaje ząb).
func _on_bagged(kind: StringName) -> void:
	_fighting["rats"].erase(kind)
	_player.set_sack(&"pimpek" if kind == &"pimpek" else &"szczur")
	if kind == &"zloty":
		gold_taken.emit()

func _on_finished(result: StringName) -> void:
	var nest := _fighting
	_fighting = {}
	hp = _battle.hp
	nest["wait"] = RESPAWN_TIME
	_show_nest(nest)
	_knife.position = KNIFE_REST
	_player.set_busy(false)
	if result == &"lost":
		hp = DEFEAT_HP
		# Przepada losowa połowa truchł z tego zejścia.
		_trip_loot.shuffle()
		var lost := ceili(_trip_loot.size() / 2.0)
		for kind in _trip_loot.slice(0, lost):
			_add_loot(kind, -1)
		_leave()
		message.emit("Szczury cię pogoniły! Zgubione truchła: %d" % lost)

# --- Budowa ---

func _build_manhole() -> void:
	var at := to_local(MANHOLE)
	var metal := B.mat("metal_brazowy", Color(0.8, 0.8, 0.8), 3.0)
	B.cyl(self, at + Vector3(0, 0.02, 0), 0.5, 0.03, metal, Vector3.ZERO, -1.0, 12)
	B.cyl(self, at + Vector3(0, 0.04, 0), 0.38, 0.02, B.mat("", Color(0.02, 0.02, 0.02)), Vector3.ZERO, -1.0, 12)
	for x in [-0.22, 0.0, 0.22]:
		B.box(self, at + Vector3(x, 0.056, 0), Vector3(0.06, 0.015, 0.7), metal)
	B.label(self, at + Vector3(0, 0.55, 0), "KANAŁY", 40, Color(0.7, 1, 0.6), 90, 0.0024).double_sided = true
	var spot := Hotspot.new()
	spot.setup(at + Vector3(0, 0.2, 0), Vector3(1.0, 0.4, 1.0), _enter_prompt, _enter)
	add_child(spot)

func _build_tunnel() -> void:
	add_child(_tunnel)
	_tunnel.visible = false # rysowany tylko, gdy gracz jest na dole
	var wall := B.mat("cegla_szara", Color(0.6, 0.7, 0.6), 0.8)
	var floor_mat := B.mat("beton", Color(0.45, 0.48, 0.42), 0.7)
	var middle := Vector3(0, 0, LENGTH / 2)
	B.box(_tunnel, middle + Vector3(0, -0.1, 0), Vector3(WIDTH, 0.2, LENGTH), floor_mat)
	B.solid(_tunnel, middle + Vector3(0, -0.1, 0), Vector3(WIDTH, 0.2, LENGTH))
	B.box(_tunnel, middle + Vector3(0, HEIGHT + 0.1, 0), Vector3(WIDTH, 0.2, LENGTH), wall)
	for side in [-1, 1]:
		var at := middle + Vector3(side * (WIDTH / 2 + 0.1), HEIGHT / 2, 0)
		B.box(_tunnel, at, Vector3(0.2, HEIGHT, LENGTH), wall)
		B.solid(_tunnel, at, Vector3(0.2, HEIGHT, LENGTH))
		B.cyl(_tunnel, middle + Vector3(side * (WIDTH / 2 - 0.15), 2.35 - side * 0.3, 0), 0.09, LENGTH,
			B.mat("metal_brazowy"), Vector3(90, 0, 0))
	for z in [-0.1, LENGTH + 0.1]:
		B.box(_tunnel, Vector3(0, HEIGHT / 2, z), Vector3(WIDTH, HEIGHT, 0.2), wall)
		B.solid(_tunnel, Vector3(0, HEIGHT / 2, z), Vector3(WIDTH, HEIGHT, 0.2))
	# ściek środkiem, brud i światła
	B.box(_tunnel, middle + Vector3(0, 0.003, 1.0), Vector3(0.9, 0.008, LENGTH - 3.0),
		B.mat("", Color(0.07, 0.16, 0.09)))
	for i in 6:
		var z := 2.5 + i * 4.0
		B.on_floor(_tunnel, "kaluza" if i % 2 else "brud", Vector3((i % 3 - 1) * 1.1, 0.012, z), 1.2,
			i * 61.0)
		B.on_wall(_tunnel, "grzyb", Vector3(-WIDTH / 2 + 0.01, 0.8, z + 1.0), Vector2(1.5, 1.2), 90)
		B.box(_tunnel, Vector3(0, HEIGHT - 0.05, z), Vector3(0.3, 0.1, 0.3), B.glow(Color(0.7, 0.9, 0.5)))
		B.light(_tunnel, Vector3(0, HEIGHT - 0.4, z), Color(0.65, 0.85, 0.45), 0.7, 4.5)
	# drabina do wyjścia
	var metal := B.mat("metal_ciemny", Color(1.4, 1.4, 1.4), 3.0)
	for x in [-0.28, 0.28]:
		B.box(_tunnel, Vector3(x, HEIGHT / 2, 0.12), Vector3(0.06, HEIGHT, 0.06), metal)
	for i in 9:
		B.box(_tunnel, Vector3(0, 0.25 + i * 0.32, 0.12), Vector3(0.56, 0.04, 0.04), metal)
	B.label(_tunnel, Vector3(0, 2.2, 0.17), "WYJŚCIE", 48, Color(0.9, 0.95, 0.7), 0, 0.0028)
	var ladder := Hotspot.new()
	ladder.setup(Vector3(0, 1.2, 0.25), Vector3(0.9, 2.0, 0.35), _ladder_prompt, _climb_out)
	add_child(ladder)

func _ladder_prompt(_who) -> String:
	return "[E] Wyjdź na górę"

func _climb_out(_who) -> void:
	_leave()

# Low-poly ręka z nożem w prawym dolnym rogu widoku. Kolory są płaskie (bez cieniowania),
# bo latarka tuż przy kamerze prześwietlałaby bryły; ściany mają ciemniejsze odcienie.
func _build_knife() -> void:
	_player.cam.add_child(_knife)
	_knife.position = KNIFE_REST
	_knife.rotation_degrees = Vector3(15, 25, 0)
	var skin := B.glow(Color(0.34, 0.23, 0.17))
	var skin_dark := B.glow(Color(0.23, 0.15, 0.12))
	var sleeve := B.glow(Color(0.07, 0.09, 0.1))
	var cuff := B.glow(Color(0.12, 0.13, 0.12))
	var grip := B.glow(Color(0.13, 0.08, 0.05))
	var steel := B.glow(Color(0.33, 0.36, 0.38))
	var edge := B.glow(Color(0.58, 0.62, 0.62))
	var guard := B.glow(Color(0.2, 0.17, 0.09))
	# rękaw i mankiet
	B.box(_knife, Vector3(0.045, -0.09, 0.2), Vector3(0.095, 0.095, 0.2), sleeve, Vector3(24, 14, 0))
	B.box(_knife, Vector3(0.024, -0.052, 0.105), Vector3(0.088, 0.088, 0.035), cuff, Vector3(24, 14, 0))
	# dłoń, palce wokół rękojeści i kciuk
	B.box(_knife, Vector3(0.014, -0.018, 0.045), Vector3(0.055, 0.07, 0.085), skin, Vector3(12, 8, 0))
	for i in 3:
		B.box(_knife, Vector3(-0.018, -0.03, 0.012 + i * 0.026), Vector3(0.045, 0.028, 0.023),
			skin if i != 1 else skin_dark, Vector3(0, 0, -14))
	B.box(_knife, Vector3(-0.002, 0.032, 0.018), Vector3(0.028, 0.022, 0.065), skin_dark, Vector3(-8, 12, 0))
	# rękojeść, jelec, ostrze ze szlifem i czubek
	B.box(_knife, Vector3(0, 0, 0.0), Vector3(0.026, 0.038, 0.12), grip)
	B.box(_knife, Vector3(0, 0.004, -0.068), Vector3(0.026, 0.092, 0.018), guard)
	B.box(_knife, Vector3(0, 0.008, -0.165), Vector3(0.009, 0.05, 0.18), steel)
	B.box(_knife, Vector3(0, -0.014, -0.165), Vector3(0.011, 0.012, 0.18), edge)
	var tip := B.cyl(_knife, Vector3(0, 0.008, -0.29), 0.025, 0.07, steel, Vector3(-90, 0, 0), 0.0, 4)
	tip.scale.x = 0.25
	_knife.visible = false
