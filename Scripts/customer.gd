extends Area3D
# Klient: wchodzi, zamawia przy ladzie, płaci, czasem je przy stoliku i wychodzi.

signal served(customer: Node, payment: int, may_sit: bool)
signal queue_changed

enum State { ENTERING, WAITING, TO_SEAT, EATING, REVIEWING, LEAVING }

const Kebab = preload("res://Scripts/kebab.gd")
const SPEED := 1.6
const AISLE_X := 0.5 # przejście wzdłuż lady
const BASE_PRICE := 20
const DOUBLE_MEAT_PRICE := 5
const MISTAKE_COST := 8
const TIP := 5
const COUNTED: Array[StringName] = [&"meat", &"salad", &"sauce", &"tortilla"]
const SPRITE_Y := 0.88
const SEATED_SPRITE_Y := 0.68
const REVIEW_TIME := 3.5
const TINTS: Array[Color] = [
	Color(0.85, 0.85, 0.9), Color(0.9, 0.65, 0.6), Color(0.6, 0.85, 0.6),
	Color(0.9, 0.85, 0.5), Color(0.75, 0.65, 0.9),
]
const RAT_REACTIONS: Array[String] = [
	"AAA! SZCZUR!!", "Ja prosiłem o kebaba, nie o zwierzaka!", "Dzwonię do sanepidu!",
]

@export var patience := 75.0

var state := State.ENTERING
var number := 0
var slot := -1 # miejsce przy ladzie
var seat := -1
var order: Array[StringName] = [] # warstwy od dołu
var strict := false # czy liczy się kolejność
var time_left := 0.0
var _path: Array[Vector3] = []
var _door := Vector3.ZERO
var _street := Vector3.ZERO
var _timer := 0.0
var _complained := false
var _opinion := ""

@onready var sprite: Sprite3D = $Sprite3D
@onready var bubble: Label3D = $Bubble
@onready var _layer := collision_layer

func _ready() -> void:
	collision_layer = 0
	sprite.modulate = TINTS.pick_random()

# Wywołać po dodaniu do sceny.
func start(new_number: int, new_slot: int, street: Vector3, door: Vector3, counter: Vector3) -> void:
	number = new_number
	slot = new_slot
	_street = street
	_door = door
	global_position = street
	_path = [door, _aisle(counter), counter]
	_make_order()

func _process(delta: float) -> void:
	match state:
		State.WAITING:
			_wait(delta)
		State.EATING:
			_timer -= delta
			if _timer <= 0.0:
				state = State.REVIEWING
				_timer = REVIEW_TIME
				bubble.text = _opinion
		State.REVIEWING:
			_timer -= delta
			if _timer <= 0.0:
				_leave(_opinion)
		_:
			_walk(delta)

func get_prompt(player) -> String:
	if not player.held:
		return "Nr %d czeka na: %s" % [number, order_summary()]
	if player.held is Kebab:
		return "[E] Podaj kebaba (nr %d)" % number
	return "[E] Daj szczura" if player.held.is_in_group("rat") else "Klient tego nie chce"

func interact(player) -> void:
	if state != State.WAITING or not player.held:
		return
	if player.held.is_in_group("rat"):
		player.discard()
		served.emit(self, 0, false)
		_leave(RAT_REACTIONS.pick_random())
	elif player.held is Kebab:
		var contents: Array[StringName] = player.held.contents
		player.discard()
		_rate(contents)

# Zamówienie w jednej linii (HUD, podpowiedź).
func order_summary() -> String:
	if strict:
		return "od dołu: " + Kebab.describe(order, " > ")
	return ", ".join(_counted_lines())

# Przydziela stolik (wywoływane przez grę w reakcji na "served").
func sit(new_seat: int, position_at_table: Vector3) -> void:
	seat = new_seat
	state = State.TO_SEAT
	slot = -1
	collision_layer = 0
	_path = [_aisle(global_position), _aisle(position_at_table), position_at_table]
	queue_changed.emit()

func _make_order() -> void:
	order = [&"meat"]
	if randf() < 0.3:
		order.append(&"meat")
	if randf() < 0.6:
		order.append(&"salad")
	if randf() < 0.6:
		order.append(&"sauce")
	if randf() < 0.15:
		order.append(&"tortilla")
	strict = order.size() > 1 and randf() < 0.3
	if strict:
		order.shuffle()

func _rate(contents: Array[StringName]) -> void:
	var mistakes := 0
	for id in COUNTED:
		mistakes += absi(contents.count(id) - order.count(id))
	var wrong_order := strict and mistakes == 0 and contents != order

	var payment := 0
	var reaction := ""
	var may_sit := false
	if &"rat" in contents:
		reaction = "W MOIM KEBABIE JEST SZCZUR!!"
	elif not &"meat" in contents:
		reaction = "Gdzie mięso?! Nie płacę!"
	else:
		var price := BASE_PRICE + DOUBLE_MEAT_PRICE * (order.count(&"meat") - 1)
		if wrong_order:
			mistakes = 1
		payment = maxi(price - mistakes * MISTAKE_COST, 0)
		may_sit = payment > 0
		reaction = "Dzięki, szefie!"
		_opinion = "Pyszny! Jeszcze tu wrócę."
		if wrong_order:
			reaction = "Kolejność nie ta..."
			_opinion = "Smaczny, ale źle ułożony."
		elif mistakes > 0:
			reaction = "Ujdzie... ale nie to zamawiałem."
			_opinion = "Zjadłem, ale bez zachwytu."
		elif time_left > patience * 0.5:
			payment += TIP
			reaction = "Ekspresowo! Reszty nie trzeba."

	served.emit(self, payment, may_sit)
	if state == State.WAITING: # nikt nie przydzielił stolika
		_leave(reaction)
	else:
		bubble.text = reaction

func _walk(delta: float) -> void:
	if _path.is_empty():
		return
	global_position = global_position.move_toward(_path[0], SPEED * delta)
	if global_position.is_equal_approx(_path[0]):
		_path.pop_front()
		if _path.is_empty():
			_arrive()

func _arrive() -> void:
	match state:
		State.ENTERING:
			state = State.WAITING
			time_left = patience
			collision_layer = _layer
			_show_order("Nr %d" % number)
			queue_changed.emit()
		State.TO_SEAT:
			state = State.EATING
			_timer = randf_range(12.0, 20.0)
			sprite.position.y = SEATED_SPRITE_Y
			bubble.text = "Mniam..."
		State.LEAVING:
			queue_free()

func _wait(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		_leave("Mam dość, idę gdzie indziej!")
	elif not _complained and time_left <= patience * 0.5:
		_complained = true
		_show_order("Nr %d - ile można czekać?!" % number)

func _leave(text: String) -> void:
	# Od stolika najpierw w bok do przejścia, od lady tak samo.
	_path = [_aisle(global_position), _door, _street]
	state = State.LEAVING
	slot = -1
	seat = -1
	collision_layer = 0
	sprite.position.y = SPRITE_Y
	bubble.text = text
	queue_changed.emit()

func _show_order(title: String) -> void:
	var lines := _counted_lines()
	if strict:
		lines.clear()
		lines.append("od dołu:")
		for i in order.size():
			lines.append("%d. %s" % [i + 1, Kebab.NAMES[order[i]]])
	bubble.text = title + "\n" + "\n".join(lines)

func _counted_lines() -> Array[String]:
	var lines: Array[String] = []
	for id in COUNTED:
		var amount := order.count(id)
		if id == &"tortilla" and amount > 0:
			lines.append("podwójna tortilla")
		elif amount > 1:
			lines.append("%dx %s" % [amount, Kebab.NAMES[id]])
		elif amount == 1:
			lines.append(Kebab.NAMES[id])
	return lines

func _aisle(point: Vector3) -> Vector3:
	return Vector3(AISLE_X, point.y, point.z)
