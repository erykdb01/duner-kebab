extends Area3D
# Szczur: łazi po kuchni, ucieka przed graczem i daje się złapać w przerwach.
# Wypuszczony w kuchni zostaje w niej, wypuszczony na sali ucieka frontowymi drzwiami.

enum State { WANDER, FLEE, HELD, ESCAPE }

const WANDER_SPEED := 1.2
const FLEE_SPEED := 3.0
const FEAR_DISTANCE := 2.0
const CATCH_WINDOW := 0.9 # postój po ucieczce
const HELD_SCALE := 0.6
const COUNTER_X := -1.35 # na lewo od tej linii jest kuchnia
const KITCHEN_EDGE_X := -2.6
const SALA_EDGE_X := -0.6
const MAX_Z := 4.7
const FLOOR_Y := 0.05

var state := State.WANDER
var _points: Array[Vector3] = []
var _exit: Array[Vector3] = []
var _escape: Array[Vector3] = []
var _player: Node3D
var _target := Vector3.ZERO
var _pause := 1.0

@onready var sprite: Sprite3D = $Sprite3D

# Wywołać po dodaniu do sceny. Szczur pojawia się z dala od gracza.
func start(points: Array[Vector3], exit: Array[Vector3], player: Node3D) -> void:
	_points = points
	_exit = exit
	_player = player
	global_position = _farthest_point()
	_target = global_position

func _process(delta: float) -> void:
	if state == State.HELD:
		return
	if state == State.ESCAPE:
		global_position = global_position.move_toward(_target, FLEE_SPEED * delta)
		if global_position.is_equal_approx(_target):
			if _escape.is_empty():
				queue_free()
			else:
				_run_to(_escape.pop_front())
		return
	var scared := global_position.distance_to(_player.global_position) < FEAR_DISTANCE
	if state == State.WANDER and scared:
		_flee()
	elif not global_position.is_equal_approx(_target):
		var speed := FLEE_SPEED if state == State.FLEE else WANDER_SPEED
		global_position = global_position.move_toward(_target, speed * delta)
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
			_run_to(_points.pick_random())

func get_prompt(player) -> String:
	return "Masz zajęte ręce" if player.held else "[E] Złap szczura"

func interact(player) -> void:
	if player.held:
		return
	state = State.HELD
	sprite.scale = Vector3.ONE * HELD_SCALE
	player.hold(self)

# Wywoływane przez gracza po "odłożeniu" szczura.
func release(point: Vector3) -> void:
	sprite.scale = Vector3.ONE
	var in_kitchen := point.x < COUNTER_X
	var x := minf(point.x, KITCHEN_EDGE_X) if in_kitchen else maxf(point.x, SALA_EDGE_X)
	global_position = Vector3(x, FLOOR_Y, clampf(point.z, -MAX_Z, MAX_Z))
	if in_kitchen:
		_flee()
	else:
		state = State.ESCAPE
		_escape = _exit.duplicate()
		_run_to(_escape.pop_front())

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
	var best := _points[0]
	for point in _points:
		if point.distance_to(_player.global_position) > best.distance_to(_player.global_position):
			best = point
	return best
