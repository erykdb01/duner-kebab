extends Area3D
# Szczur: żyje przy śmietniku, czasem zakrada się na salę. Ucieka przed graczem
# i daje się złapać w przerwach. Wypuszczony zostaje tam, gdzie wylądował.

signal consumed # zmielony, wyrzucony, zawinięty...

enum State { WANDER, FLEE, HELD, TRAVEL }

const Sfx = preload("res://Scripts/sfx.gd")
const FRAME_TIME := 0.12
const GOLD_SPEED := 1.35 # złoty szczur jest szybszy
const Night = preload("res://Scripts/night.gd")

const WANDER_SPEED := 1.2
const FLEE_SPEED := 3.0
const SNEAK_SPEED := 1.6
const FEAR_DISTANCE := 2.0
const CATCH_WINDOW := 0.9 # postój po ucieczce
const HELD_SCALE := 0.6
const SNEAK_NOTICE_TIME := 12.0 # tyle masz na złapanie, zanim klienci zauważą
const DROPPED_NOTICE_TIME := 2.0
const COUNTER_X := -1.35 # na lewo od tej linii jest kuchnia
const BACK_WALL_Z := 5.0 # dalej jest podwórko
const FLOOR_Y := 0.05
# Gdzie może wylądować wypuszczony szczur (x, z).
const BOUNDS := {
	&"yard": Rect2(-6.8, 5.4, 5.4, 7.4),
	&"kitchen": Rect2(-3.8, -4.7, 1.2, 9.4),
	&"sala": Rect2(-0.6, -4.7, 4.4, 9.4),
}

var state := State.WANDER
var zone := &"yard" # pusta w ręce i w drodze
var notice_left := 0.0
var _areas := {} # strefa -> punkty, po których szczur biega
var _path: Array[Vector3] = []
var _destination := &"" # strefa po dojściu; pusta = szczur znika
var _player: Node3D
var _target := Vector3.ZERO
var _pause := 1.0
var _frames: Array[Texture2D] = []
var _anim_time := 0.0
var _speed_scale := 1.0

@onready var sprite: Sprite3D = $Sprite3D

# Wywołać po dodaniu do sceny.
func start(areas: Dictionary, player: Node3D) -> void:
	_areas = areas
	_player = player
	global_position = _areas[zone].pick_random()
	_target = global_position

# &"szczur", &"pimpek" albo &"zloty". Wywołać po dodaniu do sceny.
func set_variant(variant: StringName) -> void:
	_frames = [
		load("res://Textures/szczury/%s_0.png" % variant),
		load("res://Textures/szczury/%s_1.png" % variant)]
	sprite.texture = _frames[0]
	if variant != &"szczur":
		add_to_group(variant)
	if variant == &"zloty":
		_speed_scale = GOLD_SPEED

# Gracz pozbywa się szczura na dobre (przed usunięciem węzła).
func consume() -> void:
	consumed.emit()

# Idzie podaną trasą na salę.
func invade(path: Array[Vector3]) -> void:
	_travel(path, &"sala")

# Idzie podaną trasą i znika.
func escape(path: Array[Vector3]) -> void:
	_travel(path, &"")

func _process(delta: float) -> void:
	sprite.modulate = Night.tint(global_position)
	$Shadow.visible = state != State.HELD
	if state == State.HELD:
		_animate(delta * 0.5) # wierzga w ręce
		return
	if state == State.TRAVEL or not global_position.is_equal_approx(_target):
		_animate(delta)
	if state == State.TRAVEL:
		_follow_path(delta)
		return
	var scared := global_position.distance_to(_player.global_position) < FEAR_DISTANCE
	if state == State.WANDER and scared:
		_flee()
	elif not global_position.is_equal_approx(_target):
		var speed := FLEE_SPEED if state == State.FLEE else WANDER_SPEED
		global_position = global_position.move_toward(_target, speed * _speed_scale * delta)
		if global_position.is_equal_approx(_target):
			_pause = CATCH_WINDOW if state == State.FLEE else randf_range(0.5, 2.0)
	else:
		_pause -= delta
		if _pause > 0.0:
			return
		if scared:
			_flee()
		else:
			state = State.WANDER
			_run_to(_areas[zone].pick_random())

func get_prompt(player) -> String:
	if player.held:
		return "Masz zajęte ręce"
	if is_in_group("pimpek"):
		return "[E] Złap szczura (ma czerwoną kokardkę)"
	if is_in_group("zloty"):
		return "[E] Złap ZŁOTEGO szczura"
	return "[E] Złap szczura"

func interact(player) -> void:
	if player.held:
		return
	state = State.HELD
	zone = &""
	sprite.scale = Vector3.ONE * HELD_SCALE
	player.hold(self)
	Sfx.play(player, "squeak")

# Wywoływane przez gracza po "odłożeniu" szczura.
func release(point: Vector3) -> void:
	sprite.scale = Vector3.ONE
	if point.z > BACK_WALL_Z:
		zone = &"yard"
	elif point.x < COUNTER_X:
		zone = &"kitchen"
	else:
		zone = &"sala"
		notice_left = DROPPED_NOTICE_TIME
	var bounds: Rect2 = BOUNDS[zone]
	global_position = Vector3(
		clampf(point.x, bounds.position.x, bounds.end.x), FLOOR_Y,
		clampf(point.z, bounds.position.y, bounds.end.y))
	_flee()

func _animate(delta: float) -> void:
	if _frames.is_empty():
		return
	_anim_time += delta
	sprite.texture = _frames[int(_anim_time / FRAME_TIME) % 2]

func _travel(path: Array[Vector3], destination: StringName) -> void:
	state = State.TRAVEL
	zone = &""
	_destination = destination
	_path = path.duplicate()
	_run_to(_path.pop_front())

func _follow_path(delta: float) -> void:
	var speed := SNEAK_SPEED if _destination else FLEE_SPEED
	global_position = global_position.move_toward(_target, speed * delta)
	if not global_position.is_equal_approx(_target):
		return
	if not _path.is_empty():
		_run_to(_path.pop_front())
	elif _destination:
		zone = _destination
		notice_left = SNEAK_NOTICE_TIME
		state = State.WANDER
		_pause = 1.0
	else:
		queue_free()

func _flee() -> void:
	state = State.FLEE
	_run_to(_farthest_point())

func _run_to(point: Vector3) -> void:
	_target = point
	var camera := get_viewport().get_camera_3d()
	if camera:
		# Tekstura jest narysowana pyskiem w prawo.
		sprite.flip_h = (point - global_position).dot(camera.global_basis.x) < 0.0

func _farthest_point() -> Vector3:
	var points: Array[Vector3] = _areas[zone]
	var best := points[0]
	for point in points:
		if point.distance_to(_player.global_position) > best.distance_to(_player.global_position):
			best = point
	return best
