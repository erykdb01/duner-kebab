extends Node3D
# Stan gry: kasa, klienci (miejsca przy ladzie i przy stolikach) i szczur.

const Customer = preload("res://Objects/customer.tscn")
const Rat = preload("res://Objects/rat.tscn")
const FIRST_DELAY := 3.0
const MIN_DELAY := 15.0
const MAX_DELAY := 28.0
const PAIR_CHANCE := 0.3
const MAX_INSIDE := 5
const SIT_CHANCE := 0.6
const RAT_DELAY := 20.0

var money := 0
var _next_number := 1
var _rat_pending := false

@onready var hud = $hud

func _ready() -> void:
	hud.show_money(money)
	$grinder.meat_ground.connect($prep_station/source_meat.refill)
	_spawn_rat()
	_schedule_customers(FIRST_DELAY)

# Gdy szczur zniknie (maszynka, kosz, kebab, klient, ucieczka), po chwili przychodzi nowy.
func _process(_delta: float) -> void:
	if not _rat_pending and get_tree().get_nodes_in_group("rat").is_empty():
		_rat_pending = true
		get_tree().create_timer(RAT_DELAY, false).timeout.connect(_spawn_rat)

func _spawn_rat() -> void:
	_rat_pending = false
	var rat = Rat.instantiate()
	add_child(rat)
	var exit: Array[Vector3] = [
		$customer_route/door.global_position, $customer_route/street.global_position,
	]
	rat.start(_marker_positions($rat_points), exit, $player)

func _schedule_customers(delay: float) -> void:
	get_tree().create_timer(delay, false).timeout.connect(_spawn_group)

# Przychodzi jedna osoba albo para, o ile jest miejsce.
func _spawn_group() -> void:
	var group_size := 2 if randf() < PAIR_CHANCE else 1
	for i in group_size:
		_spawn_customer(i)
	_schedule_customers(randf_range(MIN_DELAY, MAX_DELAY))

func _spawn_customer(place_in_group: int) -> void:
	var slot := _free_index($counter_slots, &"slot")
	if slot < 0 or _customers_inside() >= MAX_INSIDE:
		return
	var customer = Customer.instantiate()
	add_child(customer)
	customer.served.connect(_on_served)
	customer.queue_changed.connect(_refresh_orders)
	# Druga osoba z pary idzie krok za pierwszą.
	var street: Vector3 = $customer_route/street.global_position + Vector3(0, 0, -0.9 * place_in_group)
	customer.start(_next_number, slot, street, $customer_route/door.global_position,
		$counter_slots.get_child(slot).global_position)
	_next_number += 1

func _on_served(customer: Node, payment: int, may_sit: bool) -> void:
	money += payment
	hud.show_money(money)
	hud.show_payment(payment)
	var seat := _free_index($seats, &"seat")
	if may_sit and seat >= 0 and randf() < SIT_CHANCE:
		customer.sit(seat, $seats.get_child(seat).global_position)

func _refresh_orders() -> void:
	var lines: Array[String] = []
	for customer in get_tree().get_nodes_in_group("customers"):
		if customer.state == customer.State.WAITING:
			lines.append("Nr %d: %s" % [customer.number, customer.order_summary()])
	hud.show_orders(lines)

# Pierwszy marker, którego numeru nie zajmuje żaden klient (-1 = brak).
func _free_index(markers: Node, property: StringName) -> int:
	var taken := get_tree().get_nodes_in_group("customers").map(
		func(customer): return customer.get(property))
	for i in markers.get_child_count():
		if not i in taken:
			return i
	return -1

func _customers_inside() -> int:
	return get_tree().get_nodes_in_group("customers").filter(
		func(customer): return customer.state != customer.State.LEAVING).size()

func _marker_positions(parent: Node) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for marker in parent.get_children():
		positions.append(marker.global_position)
	return positions
