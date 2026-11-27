extends Node3D
# Stan gry: trzy noce, kasa, klienci (miejsca przy ladzie i przy stolikach), szczury i finał.

const Customer = preload("res://Objects/customer.tscn")
const Rat = preload("res://Objects/rat.tscn")
const Sfx = preload("res://Scripts/sfx.gd")
const Dialogs = preload("res://Scripts/dialogs.gd")
# Kto przychodzi w kolejnych nocach (kolejność jest losowana).
const NIGHTS: Array = [
	[&"regular", &"regular", &"regular", &"regular", &"regular", &"regular", &"regular",
		&"regular", &"student", &"babcia", &"smakosz"],
	[&"regular", &"regular", &"regular", &"regular", &"regular", &"regular", &"regular",
		&"regular", &"regular", &"student", &"smakosz", &"sanepid", &"wlasciciel"],
	[&"regular", &"regular", &"regular", &"regular", &"regular", &"regular", &"regular",
		&"regular", &"regular", &"regular", &"regular", &"student", &"smakosz", &"sanepid",
		&"wlasciciel"],
]
# Postacie z dialogi.json, które na razie nie przychodzą (babcia to jedyna "babcia").
const DISABLED: Array[String] = ["krystyna"]
const SPECIALS: Array[StringName] = [&"smakosz", &"sanepid", &"wlasciciel"]
const RENT := 500
const FINE := 40
const PIMPEK_REWARD := 60
const GOLD_BONUS := 50
const GOLD_CHANCE := 0.2 # od 2. nocy, przy każdym nowym szczurze
const NIGHT_LENGTH := 480.0 # tyle sekund zajmuje zegarowi dojście do 04:00
const CLOCK_START := 22 * 60 # minuty
const CLOCK_SPAN := 6 * 60
const FIRST_DELAY := 3.0
const MIN_DELAY := 28.0
const MAX_DELAY := 45.0
const PICKUP_SLOT := 3 # miejsce odbioru dla zawołanych (poza trzema miejscami w kolejce)
const PAIR_CHANCE := 0.3
const MAX_INSIDE := 5
const SIT_CHANCE := 0.6
const MAX_RATS := 2
const RAT_DELAY := 20.0
const MIN_INVASION_DELAY := 140.0
const MAX_INVASION_DELAY := 240.0
const SNEAK_MIN_DISTANCE := 4.0 # szczur nie zakrada się przy graczu
const SALA_X := -1.0 # na prawo od tej linii jest sala
const REVIEWS_SHOWN := 3

# Stan na początek bieżącej nocy; przeżywa przeładowanie sceny. Pusty = nowa gra.
static var save := {}

var night := 1
var money := 0
var pimpek := "free" # free, returned, dead
var fines := 0
var rat_kebabs := 0 # kebaby ze szczurem podane komukolwiek poza smakoszem
var _gold_seen := false
var _rat_pending := false
var _night_running := false
var _elapsed := 0.0
var _queue: Array[StringName] = [] # klienci, którzy jeszcze nie przyszli
var _expected := 0 # płacący klienci tej nocy (bez właścicielki Pimpka)
var _paid := 0
var _earned := 0
var _rats_ground := 0
var _night_fines := 0
var _reviews: Array[Dictionary] = []
var _used_names: Array = []
var _used_characters: Array = []

static func new_game() -> void:
	save = {}

@onready var hud = $hud
@onready var overlay = $overlay

func _ready() -> void:
	Dialogs.reload()
	_load_state()
	_build_queue()
	$dialog_box.player = $player
	$dialog_box.notebook = $notebook
	$dialog_box.closed.connect(_on_talk_closed)
	$notebook.player = $player
	$notebook.dialog = $dialog_box
	$notebook.shouted.connect(_on_shout)
	hud.show_money(money, RENT)
	_show_clock("Zamknięte (tabliczka przy drzwiach)")
	$grinder.meat_ground.connect($prep_station/source_meat.refill)
	$grinder.meat_ground.connect(func(_portions): _rats_ground += 1)
	$grinder.gold_found.connect(_on_gold_found)
	$open_sign.opened.connect(_start_night)
	Sfx.make_loop($ambient, "night")
	$ambient.play()
	_refresh_poster()
	for i in MAX_RATS:
		_spawn_rat()
	if night == 1:
		hud.show_message(
			("Uzbieraj %d zł na czynsz do końca %d. nocy.\nPytaj klientów o zamówienie i imię, "
			+ "zapisuj w notatniku [Tab].\nObróć tabliczkę przy drzwiach, żeby otworzyć.")
			% [RENT, NIGHTS.size()], 14.0)

func _process(delta: float) -> void:
	# Gdy szczurów ubędzie, po chwili przy śmietniku pojawia się nowy.
	if not _rat_pending and get_tree().get_nodes_in_group("rat").size() < MAX_RATS:
		_rat_pending = true
		get_tree().create_timer(RAT_DELAY, false).timeout.connect(_spawn_rat)
	_watch_held_rat()
	_watch_sala_rats(delta)
	if _night_running:
		_run_night(delta)

# --- Stan między nocami ---

func _load_state() -> void:
	night = save.get("night", 1)
	money = save.get("money", 0)
	pimpek = save.get("pimpek", "free")
	fines = save.get("fines", 0)
	rat_kebabs = save.get("rat_kebabs", 0)
	_gold_seen = save.get("gold_seen", false)
	if save.has("meat"):
		$prep_station/source_meat.set_stock(save["meat"])

func _next_state() -> Dictionary:
	return {
		"night": night + 1, "money": money, "pimpek": pimpek, "fines": fines,
		"rat_kebabs": rat_kebabs, "gold_seen": _gold_seen,
		"meat": $prep_station/source_meat.stock,
	}

# --- Noc ---

func _build_queue() -> void:
	_queue.assign(NIGHTS[night - 1])
	# Oddanego Pimpka nie ma po co szukać.
	if pimpek == "returned":
		var index := _queue.find(&"wlasciciel")
		if index >= 0:
			_queue[index] = &"regular"
	_queue.shuffle()
	# Na początek zawsze ktoś zwyczajny.
	for i in _queue.size():
		if not _queue[i] in SPECIALS:
			var first := _queue[0]
			_queue[0] = _queue[i]
			_queue[i] = first
			break
	_expected = _queue.size() - _queue.count(&"wlasciciel")

func _start_night() -> void:
	_night_running = true
	_schedule_customers(FIRST_DELAY)
	_schedule_invasion()

# Zegar jest dekoracyjny; noc kończy się, gdy ostatni klient zniknie.
func _run_night(delta: float) -> void:
	_elapsed += delta
	var passed := minf(_elapsed / NIGHT_LENGTH, 1.0) * CLOCK_SPAN
	var minutes := CLOCK_START + int(passed / 10.0) * 10
	_show_clock("%02d:%02d" % [floori(minutes / 60.0) % 24, minutes % 60])
	if _queue.is_empty() and get_tree().get_nodes_in_group("customers").is_empty():
		_end_night()

func _show_clock(text: String) -> void:
	hud.show_clock("Noc %d/%d · %s" % [night, NIGHTS.size(), text])

func _end_night() -> void:
	_night_running = false
	$dialog_box.close()
	$notebook.close()
	var text := "Zarobek tej nocy: %d zł\nKasa: %d zł (czynsz: %d zł)\nZapłacili: %d z %d\nZmielone szczury: %d" % [
		_earned, money, RENT, _paid, _expected, _rats_ground]
	if _night_fines > 0:
		text += "\nMandaty: %d zł" % (_night_fines * FINE)
	text += "\n\n" + _review_text()
	if night < NIGHTS.size():
		Sfx.play(overlay, "win")
		overlay.show_summary("Koniec nocy %d" % night, text, "Następna noc", _next_night)
	else:
		overlay.show_summary("Koniec nocy %d" % night, text, "Zobacz finał", _show_finale)

func _next_night() -> void:
	save = _next_state()
	get_tree().paused = false
	get_tree().reload_current_scene()

# Średnia ocena i kilka losowych komentarzy z tej nocy.
func _review_text() -> String:
	if _reviews.is_empty():
		return "Brak opinii."
	var total := 0
	for review in _reviews:
		total += review["stars"]
	var lines: Array[String] = ["Ocena lokalu: %.1f / 5" % (float(total) / _reviews.size())]
	var picked := _reviews.duplicate()
	picked.shuffle()
	for review in picked.slice(0, REVIEWS_SHOWN):
		var stars: int = review["stars"]
		lines.append("%d/5  %s: \"%s\"" % [stars, review["author"], review["text"]])
	return "\n".join(lines)

# --- Finał ---

func _show_finale() -> void:
	var paid := money >= RENT
	var heading := ""
	var text := ""
	if paid and pimpek == "returned" and fines == 0 and rat_kebabs == 0:
		heading = "ZŁOTY KEBAB"
		text = "Czynsz opłacony, sanepid zachwycony, a Pimpek wrócił do domu.\n" \
			+ "Pani od Pimpka okazała się właścicielką kamienicy.\n" \
			+ "Od dziś czynsz wynosi zero. Pimpek wpada na surówkę."
	elif paid and pimpek == "dead":
		heading = "Król kebaba"
		text = "Czynsz opłacony. Interes kwitnie.\n" \
			+ "Tylko co noc ktoś stoi przed szybą ze zdjęciem szczura\n" \
			+ "w czerwonej kokardce i patrzy prosto na ciebie."
	elif paid and fines >= 2:
		heading = "Na warunkowym"
		text = "Czynsz opłacony, ale sanepid ma już twój numer.\n" \
			+ "I klucz do zaplecza. I własny kubek."
	elif paid:
		heading = "Lokal uratowany"
		text = "Czynsz opłacony! Właściciel kamienicy wziął pieniądze\n" \
			+ "i kebaba na drogę. Nie pytał o mięso."
	elif fines > 0:
		heading = "Zamknięte przez sanepid"
		text = "Zabrakło %d zł, a na drzwiach wisi plomba.\n" % (RENT - money) \
			+ "Szczury organizują parapetówkę."
	else:
		heading = "Eksmisja"
		text = "Zabrakło %d zł. Lokal przejmują nowi najemcy:\n" % (RENT - money) \
			+ "rodzina szczurów. Płacą w terminie."
	text += "\n\nKasa: %d zł / czynsz %d zł\nMandaty: %d\nKoniec gry. Dzięki za nocną zmianę!" % [
		money, RENT, fines]
	Sfx.play(overlay, "win" if paid else "lose")
	overlay.show_finale(heading, text)

# --- Szczury ---

func _spawn_rat() -> void:
	_rat_pending = false
	var rat = Rat.instantiate()
	add_child(rat)
	var areas := {}
	for area in $rat_areas.get_children():
		areas[StringName(area.name)] = _marker_positions(area)
	rat.start(areas, $player)
	var variant := &"szczur"
	if pimpek == "free" and get_tree().get_nodes_in_group("pimpek").is_empty():
		variant = &"pimpek"
		rat.consumed.connect(_on_pimpek_consumed)
	elif night > 1 and not _gold_seen and _night_running and randf() < GOLD_CHANCE * night:
		variant = &"zloty"
		_gold_seen = true
	rat.set_variant(variant)

func _on_pimpek_consumed() -> void:
	if pimpek != "free":
		return
	pimpek = "dead"
	hud.show_message("To był Pimpek...", 4.0)

func _on_pimpek_returned(_customer: Node) -> void:
	pimpek = "returned"
	_add_money(PIMPEK_REWARD)
	hud.show_message("Pimpek wraca do domu! Nagroda: %d zł" % PIMPEK_REWARD, 5.0)
	_refresh_poster()

func _on_gold_found() -> void:
	_add_money(GOLD_BONUS)
	hud.show_message("Maszynka wypluła złoty ząb! +%d zł" % GOLD_BONUS, 5.0)

func _refresh_poster() -> void:
	if pimpek == "returned":
		$poster/Title.text = "PIMPEK\nW DOMU!"
		$poster/Note.text = "dziękujemy\nkucharzowi"

func _schedule_invasion() -> void:
	var delay := randf_range(MIN_INVASION_DELAY, MAX_INVASION_DELAY)
	get_tree().create_timer(delay, false).timeout.connect(_on_invasion_time)

func _on_invasion_time() -> void:
	_schedule_invasion()
	_invade()

# Szczur z podwórka zakrada się przez kuchnię na salę (najwyżej jeden naraz).
func _invade() -> void:
	var candidates := []
	for rat in get_tree().get_nodes_in_group("rat"):
		if rat.zone == &"sala" or rat.state == rat.State.TRAVEL:
			return
		if rat.zone == &"yard" \
				and rat.global_position.distance_to($player.global_position) > SNEAK_MIN_DISTANCE:
			candidates.append(rat)
	if candidates:
		var intruder = candidates.pick_random()
		intruder.invade(_marker_positions($invasion_route))
		Sfx.play_at(intruder, "squeak")

# Sanepid widzi też szczura niesionego w ręce po sali.
func _watch_held_rat() -> void:
	var player = $player
	if not player.held or not player.held.is_in_group("rat"):
		return
	var at: Vector3 = player.global_position
	if at.x < SALA_X or absf(at.z) > 5.0:
		return
	for customer in get_tree().get_nodes_in_group("customers"):
		if customer.kind == &"sanepid" and customer.can_see_rat():
			customer.see_rat()

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
	var group_size := mini(2 if randf() < PAIR_CHANCE else 1, _queue.size())
	for i in group_size:
		_spawn_customer(i)
	if not _queue.is_empty():
		_schedule_customers(randf_range(MIN_DELAY, MAX_DELAY))

func _spawn_customer(place_in_group: int) -> void:
	var slot := _free_index($counter_slots, &"slot")
	if slot < 0 or _customers_inside() >= MAX_INSIDE or _queue.is_empty():
		return
	var customer = Customer.instantiate()
	add_child(customer)
	customer.served.connect(_on_served)
	customer.fined.connect(_on_fined)
	customer.rat_served.connect(func(): rat_kebabs += 1)
	customer.reviewed.connect(_on_reviewed)
	customer.pimpek_returned.connect(_on_pimpek_returned)
	# Druga osoba z pary idzie krok za pierwszą.
	var street: Vector3 = $customer_route/street.global_position + Vector3(0, 0, -0.9 * place_in_group)
	customer.talk_requested.connect($dialog_box.open)
	var type_id: StringName = _queue.pop_front()
	var options := Dialogs.characters_of(type_id).filter(
		func(id): return not id in DISABLED)
	var character: String = _pick_unused(options, _used_characters, type_id)
	var gender: String = Dialogs.character(character).get("plec", "m")
	var first_name: String = _pick_unused(Dialogs.names(gender), _used_names, "Alex")
	customer.start(type_id, character, first_name, slot, street,
		$customer_route/door.global_position, $counter_slots.get_child(slot).global_position)
	Sfx.play_at($open_sign, "bell")

# Losuje coś, czego tej nocy jeszcze nie było (a gdy wszystko było, cokolwiek).
func _pick_unused(options: Array, used: Array, fallback: String) -> String:
	if options.is_empty():
		return fallback
	var fresh := options.filter(func(option): return not option in used)
	var picked: String = (fresh if fresh else options).pick_random()
	used.append(picked)
	return picked

# Po przyjęciu zamówienia klient idzie czekać do stolika (jeśli jest wolny).
func _on_talk_closed(customer: Node) -> void:
	if customer.ordered and not customer.fed and not customer.called and customer.seat < 0 \
			and customer.state == customer.State.WAITING:
		_seat_customer(customer)

func _seat_customer(customer: Node) -> void:
	var seat := _free_index($seats, &"seat")
	if seat >= 0:
		customer.sit(seat, $seats.get_child(seat).global_position)

# --- Wołanie po imieniu ---

func _on_shout(text: String) -> void:
	var wanted := _plain(text)
	for customer in get_tree().get_nodes_in_group("customers"):
		if not customer.is_hungry() or _plain(customer.first_name) != wanted:
			continue
		hud.show_message("Wołasz: \"%s!\"" % customer.first_name, 2.0)
		if customer.seat < 0:
			customer.say_already_here()
		else:
			_call_to_counter(customer)
		return
	hud.show_message("Wołasz: \"%s!\"\nNikt się nie odzywa." % text, 3.0)

func _call_to_counter(customer: Node) -> void:
	var taken := get_tree().get_nodes_in_group("customers").map(
		func(other): return other.slot)
	if not PICKUP_SLOT in taken:
		customer.come_to_counter(PICKUP_SLOT, $pickup.global_position)
		return
	var slot := _free_index($counter_slots, &"slot")
	if slot < 0:
		hud.show_message("Przy ladzie tłok, nie ma gdzie podejść.", 3.0)
		return
	customer.come_to_counter(slot, $counter_slots.get_child(slot).global_position)

# Imię bez wielkości liter, polskich znaków i wykrzykników.
func _plain(text: String) -> String:
	var plain := text.to_lower().replace("!", "").strip_edges()
	for pair in ["ąa", "ćc", "ęe", "łl", "ńn", "óo", "śs", "źz", "żz"]:
		plain = plain.replace(pair[0], pair[1])
	return plain

func _on_served(customer: Node, payment: int, may_sit: bool) -> void:
	if payment > 0:
		_paid += 1
		_add_money(payment)
		Sfx.play($player, "cash")
	# Obsłużony przy ladzie czasem idzie zjeść do stolika.
	if may_sit and customer.seat < 0 and randf() < SIT_CHANCE:
		_seat_customer(customer)

func _add_money(amount: int) -> void:
	money += amount
	_earned += amount
	hud.show_money(money, RENT)
	hud.show_payment(amount)

func _on_fined() -> void:
	fines += 1
	_night_fines += 1
	money -= FINE
	hud.show_money(money, RENT)
	hud.show_payment(-FINE)
	hud.show_message("To był SANEPID! Mandat: %d zł" % FINE, 5.0)
	Sfx.play($player, "whistle")

func _on_reviewed(stars: int, text: String, author: String) -> void:
	_reviews.append({"stars": stars, "text": text, "author": author})

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
