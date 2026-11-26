extends Node3D
# Stan gry: noc, kasa, klienci (miejsca przy ladzie i przy stolikach) i szczury.

const Customer = preload("res://Objects/customer.tscn")
const Rat = preload("res://Objects/rat.tscn")
const NIGHT_CUSTOMERS := 9
const NIGHT_LENGTH := 270.0 # tyle sekund zajmuje zegarowi dojście do 04:00
const CLOCK_START := 22 * 60 # minuty
const CLOCK_SPAN := 6 * 60
const FIRST_DELAY := 3.0
const MIN_DELAY := 22.0
const MAX_DELAY := 38.0
const PAIR_CHANCE := 0.3
const MAX_INSIDE := 5
const SIT_CHANCE := 0.6
const MAX_RATS := 2
const RAT_DELAY := 20.0
const MIN_INVASION_DELAY := 45.0
const MAX_INVASION_DELAY := 90.0
const SNEAK_MIN_DISTANCE := 4.0 # szczur nie zakrada się przy graczu

var money := 0
var _next_number := 1
var _rat_pending := false
var _night_running := false
var _elapsed := 0.0
var _to_come := NIGHT_CUSTOMERS # klienci, którzy jeszcze nie przyszli
var _paid := 0
var _rats_ground := 0

@onready var hud = $hud

func _ready() -> void:
	hud.show_money(money)
	hud.show_clock("Zamknięte (tabliczka przy drzwiach)")
	$grinder.meat_ground.connect($prep_station/source_meat.refill)
	$grinder.meat_ground.connect(func(_portions): _rats_ground += 1)
	$open_sign.opened.connect(_start_night)
	for i in MAX_RATS:
		_spawn_rat()

func _process(delta: float) -> void:
	# Gdy szczurów ubędzie, po chwili przy śmietniku pojawia się nowy.
	if not _rat_pending and get_tree().get_nodes_in_group("rat").size() < MAX_RATS:
		_rat_pending = true
		get_tree().create_timer(RAT_DELAY, false).timeout.connect(_spawn_rat)
	_watch_sala_rats(delta)
	_refresh_orders()
	if _night_running:
		_run_night(delta)

# --- Noc ---

func _start_night() -> void:
	_night_running = true
	_schedule_customers(FIRST_DELAY)
	_schedule_invasion()

# Zegar jest dekoracyjny; noc kończy się, gdy ostatni klient zniknie.
func _run_night(delta: float) -> void:
	_elapsed += delta
	var passed := minf(_elapsed / NIGHT_LENGTH, 1.0) * CLOCK_SPAN
	var minutes := CLOCK_START + int(passed / 10.0) * 10
	hud.show_clock("%02d:%02d" % [floori(minutes / 60.0) % 24, minutes % 60])
	if _to_come == 0 and get_tree().get_nodes_in_group("customers").is_empty():
		_end_night()

func _end_night() -> void:
	_night_running = false
	$overlay.show_summary("Zarobek: %d zł\nZapłacili: %d z %d\nStraceni klienci: %d\nZmielone szczury: %d" % [
		money, _paid, NIGHT_CUSTOMERS, NIGHT_CUSTOMERS - _paid, _rats_ground])

# --- Szczury ---

func _spawn_rat() -> void:
	_rat_pending = false
	var rat = Rat.instantiate()
	add_child(rat)
	var areas := {}
	for area in $rat_areas.get_children():
		areas[StringName(area.name)] = _marker_positions(area)
	rat.start(areas, $player)

func _schedule_invasion() -> void:
	var delay := randf_range(MIN_INVASION_DELAY, MAX_INVASION_DELAY)
	get_tree().create_timer(delay, false).timeout.connect(_invade)

# Szczur z podwórka zakrada się przez kuchnię na salę (najwyżej jeden naraz).
func _invade() -> void:
	_schedule_invasion()
	var candidates := []
	for rat in get_tree().get_nodes_in_group("rat"):
		if rat.zone == &"sala" or rat.state == rat.State.TRAVEL:
			return
		if rat.zone == &"yard" \
				and rat.global_position.distance_to($player.global_position) > SNEAK_MIN_DISTANCE:
			candidates.append(rat)
	if candidates:
		candidates.pick_random().invade(_marker_positions($invasion_route))

# Klienci zauważają szczura na sali po chwili i wychodzą.
func _watch_sala_rats(delta: float) -> void:
	var witnesses := get_tree().get_nodes_in_group("customers").filter(
		func(customer): return customer.can_see_rat())
	var warning := ""
	for rat in get_tree().get_nodes_in_group("rat"):
		if rat.zone != &"sala":
			continue
		if witnesses.is_empty():
			warning = "Szczur na sali!"
			continue
		rat.notice_left -= delta
		if rat.notice_left > 0.0:
			warning = "Szczur na sali! Złap go: %d s" % ceili(rat.notice_left)
			continue
		for customer in witnesses:
			customer.see_rat()
		witnesses.clear()
		rat.escape(_front_exit())
	hud.show_warning(warning)

func _front_exit() -> Array[Vector3]:
	return [$customer_route/door.global_position, $customer_route/street.global_position]

# --- Klienci ---

func _schedule_customers(delay: float) -> void:
	get_tree().create_timer(delay, false).timeout.connect(_spawn_group)

# Przychodzi jedna osoba albo para, o ile jest miejsce.
func _spawn_group() -> void:
	var group_size := mini(2 if randf() < PAIR_CHANCE else 1, _to_come)
	for i in group_size:
		_spawn_customer(i)
	if _to_come > 0:
		_schedule_customers(randf_range(MIN_DELAY, MAX_DELAY))

func _spawn_customer(place_in_group: int) -> void:
	var slot := _free_index($counter_slots, &"slot")
	if slot < 0 or _customers_inside() >= MAX_INSIDE:
		return
	var customer = Customer.instantiate()
	add_child(customer)
	customer.served.connect(_on_served)
	# Druga osoba z pary idzie krok za pierwszą.
	var street: Vector3 = $customer_route/street.global_position + Vector3(0, 0, -0.9 * place_in_group)
	customer.start(_next_number, slot, street, $customer_route/door.global_position,
		$counter_slots.get_child(slot).global_position)
	_next_number += 1
	_to_come -= 1

func _on_served(customer: Node, payment: int, may_sit: bool) -> void:
	money += payment
	if payment > 0:
		_paid += 1
	hud.show_money(money)
	hud.show_payment(payment)
	var seat := _free_index($seats, &"seat")
	if may_sit and seat >= 0 and randf() < SIT_CHANCE:
		customer.sit(seat, $seats.get_child(seat).global_position)

# Lista zamówień z czasem, który został (lewy górny róg).
func _refresh_orders() -> void:
	var lines: Array[String] = []
	for customer in get_tree().get_nodes_in_group("customers"):
		if customer.state == customer.State.WAITING:
			lines.append("Nr %d (%d s): %s" % [
				customer.number, ceili(customer.time_left), customer.order_summary()])
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
