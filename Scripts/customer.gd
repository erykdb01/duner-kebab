extends Area3D
# Klient: wchodzi, rozmawia i zamawia przy ladzie, czeka (zwykle przy stoliku), dostaje kebaba
# do ręki albo podchodzi zawołany po imieniu, płaci, czasem je i wychodzi.
# Zachowanie zależy od rodzaju (CustomerType), teksty od postaci z Data/dialogi.json.

signal served(customer: Node, payment: int, may_sit: bool)
signal talk_requested(customer: Node)
signal fined
signal rat_served # kebab ze szczurem dla kogoś, kto go nie zamawiał
signal reviewed(stars: int, text: String, author: String)
signal pimpek_returned(customer: Node)

enum State { ENTERING, WAITING, WALKING, EATING, FAREWELL, LEAVING }

const Kebab = preload("res://Scripts/kebab.gd")
const CustomerType = preload("res://Scripts/customer_type.gd")
const Dialogs = preload("res://Scripts/dialogs.gd")
const Sfx = preload("res://Scripts/sfx.gd")
const Night = preload("res://Scripts/night.gd")
const LOOK := "res://Textures/postacie/%s.png"
const SPEED := 1.6
const AISLE_X := 0.5 # przejście wzdłuż lady
const BASE_PRICE := 20
const DOUBLE_MEAT_PRICE := 5
const MISTAKE_COST := 8
const COUNTED: Array[StringName] = [&"meat", &"rat", &"salad", &"sauce", &"tortilla"]
const SPRITE_Y := 0.88
const SEATED_SPRITE_Y := 0.68
const FOOD_PATIENCE := 1.8 # po przyjęciu zamówienia czeka dłużej
const REPEAT_COST := 8.0 # sekundy cierpliwości za prośbę o powtórzenie
const MAX_CHATS := 2
const FRONT_WALL_Z := -5.0

var type: CustomerType
var character := "" # klucz w "postacie"
var first_name := ""
var name_known := false
var state := State.ENTERING
var slot := -1 # miejsce przy ladzie
var seat := -1
var ordered := false
var fed := false
var called := false # zawołany po imieniu, czeka przy ladzie
var talking := false # w trakcie rozmowy cierpliwość stoi
var chats := 0
var last_words := ""
var drain := 1.0 # tempo utraty cierpliwości (radio uspokaja, ciemność denerwuje)
var order: Array[StringName] = [] # warstwy od dołu
var strict := false # czy liczy się kolejność
var time_left := 0.0
var _max_time := 1.0
var _bonus_tip := 0
var _greeted := false
var _conversations: Array = []
var _path: Array[Vector3] = []
var _door := Vector3.ZERO
var _street := Vector3.ZERO
var _timer := 0.0
var _bubble_time := 0.0
var _walk_time := 0.0
var _complained := false
var _opinion := ""
var _stars := 3

@onready var sprite: Sprite3D = $Sprite3D
@onready var bubble: Label3D = $Bubble
@onready var _layer := collision_layer

func _ready() -> void:
	collision_layer = 0

# Wywołać po dodaniu do sceny.
func start(new_type: CustomerType, new_character: String, new_name: String, new_slot: int,
		street: Vector3, door: Vector3, counter: Vector3) -> void:
	type = new_type
	character = new_character
	first_name = new_name
	# Wygląd: pole "wyglad" w pliku dialogów albo obrazek o nazwie postaci.
	var look := LOOK % str(Dialogs.character(character).get("wyglad", character))
	sprite.texture = load(look if ResourceLoader.exists(look) else LOOK % "zwykly")
	slot = new_slot
	_street = street
	_door = door
	global_position = street
	_path = [door, _aisle(counter), counter]
	_conversations = Dialogs.conversations(character, type.kind != &"owner")
	_make_order()

func _process(delta: float) -> void:
	sprite.modulate = Night.tint(global_position)
	if _bubble_time > 0.0:
		_bubble_time -= delta
		if _bubble_time <= 0.0:
			bubble.text = ""
	match state:
		State.WAITING:
			if not talking:
				_wait(delta)
		State.EATING:
			if not talking:
				_timer -= delta
				if _timer <= 0.0:
					_leave(_opinion, _stars, _opinion)
		State.FAREWELL:
			# Najpierw mówi, co ma do powiedzenia, potem wychodzi.
			_timer -= delta
			if _timer <= 0.0:
				_walk_out()
		_:
			_walk(delta)

func get_prompt(player) -> String:
	if not player.held:
		return "[E] Porozmawiaj"
	if player.held is Kebab:
		return "[E] Podaj kebaba"
	if type.kind == &"owner" and player.held.is_in_group("pimpek"):
		return "[E] Oddaj Pimpka"
	return "[E] Daj szczura" if player.held.is_in_group("rat") else "Klient tego nie chce"

func interact(player) -> void:
	if not player.held:
		if state == State.WAITING or state == State.EATING:
			bubble.text = ""
			talk_requested.emit(self)
		return
	if state != State.WAITING:
		return
	if type.kind == &"owner":
		_owner_takes(player)
	elif player.held.is_in_group("rat"):
		player.discard()
		served.emit(self, 0, false)
		if type.kind == &"gourmet":
			_leave(_line("surowy_szczur"), 2, _line("opinia_surowy_szczur"))
		elif type.kind == &"sanepid":
			_fine()
		else:
			_leave(_line("szczur_do_reki"), 1, _line("opinia_szczur"))
	elif player.held is Kebab:
		if not ordered:
			_say(_line("nie_zamowione"))
			return
		var contents: Array[StringName] = player.held.contents
		player.discard()
		_rate(contents)

# --- Rozmowa (wywoływane przez okno dialogu) ---

func display_name() -> String:
	return first_name if name_known else str(Dialogs.character(character).get("tytul", "Klient"))

func greet() -> String:
	if state == State.EATING:
		return _line("smacznego")
	var key := "czekam" if _greeted else "powitania"
	_greeted = true
	return _line(key)

func can_take_order() -> bool:
	return type.kind != &"owner" and state == State.WAITING

func ask_order() -> String:
	if not ordered:
		ordered = true
		_max_time = type.patience * FOOD_PATIENCE
		time_left = _max_time
		_complained = false
		return _order_text()
	time_left = maxf(time_left - REPEAT_COST, 5.0)
	return _line("powtorka", {"zamowienie": _order_text()})

func ask_name() -> String:
	name_known = true
	return _line("imie", {"imie": first_name})

func can_chat() -> bool:
	return chats < MAX_CHATS and not _conversations.is_empty()

func next_conversation() -> Dictionary:
	chats += 1
	return _conversations.pop_front()

func tired_of_chat() -> String:
	return _line("dosc_gadania")

# Skutki wybranej odpowiedzi. Zwraca reakcję klienta.
func apply_reply(reply: Dictionary) -> String:
	var reaction := str(reply.get("klient", "..."))
	_bonus_tip += int(reply.get("napiwek", 0))
	var seconds := float(reply.get("cierpliwosc", 0))
	if state == State.WAITING and seconds != 0.0:
		time_left = clampf(time_left + seconds, 5.0, _max_time)
	if reply.get("wychodzi", false) and state == State.WAITING:
		_leave(reaction, 1, _line("obrazony"))
	return reaction

# Właścicielce powiedziano, że Pimpka nie ma.
func dismiss() -> void:
	_leave(_line("nie_widziano"), 2, _line("opinia_rezygnacja"))

# --- Stolik i wołanie ---

# Idzie do stolika (czekać albo jeść).
func sit(new_seat: int, position_at_table: Vector3) -> void:
	seat = new_seat
	slot = -1
	_walk_to(position_at_table)
	if not fed:
		_say(_line("po_zamowieniu"))

# Zawołany po imieniu: wraca do lady.
func come_to_counter(new_slot: int, counter: Vector3) -> void:
	slot = new_slot
	seat = -1
	called = true
	_walk_to(counter)
	_say(_line("zawolany"))

func say_already_here() -> void:
	_say(_line("juz_stoje"))

func is_hungry() -> bool:
	return not fed and (state == State.WAITING or state == State.WALKING)

# --- Szczury i światło ---

# Czy klient jest w lokalu i może się przejąć szczurem.
func can_see_rat() -> bool:
	if type.kind == &"gourmet" or type.kind == &"owner":
		return false
	return state != State.FAREWELL and state != State.LEAVING and global_position.z > FRONT_WALL_Z

func see_rat() -> void:
	if type.kind == &"sanepid":
		_fine()
	else:
		_leave(_line("widzi_szczura"), 1, _line("opinia_widzial_szczura"))

# --- Wewnętrzne ---

func _line(key: String, values := {}) -> String:
	return Dialogs.line(character, key, values)

# Dymek nad głową, znika po chwili.
func _say(text: String) -> void:
	bubble.text = text
	_bubble_time = 4.0

func _fine() -> void:
	fined.emit()
	_leave(_line("mandat"), 1, _line("opinia_widzial_szczura"))

func _owner_takes(player) -> void:
	if player.held.is_in_group("pimpek"):
		pimpek_returned.emit(self)
		player.discard()
		_leave(_line("pimpek_oddany"), 5, _line("opinie_super"))
	elif player.held.is_in_group("rat"):
		_say(_line("nie_pimpek"))
	elif player.held is Kebab:
		if not &"rat" in player.held.contents:
			_say(_line("nie_glodna"))
			return
		player.discard()
		rat_served.emit()
		served.emit(self, 0, false)
		_leave(_line("pimpek_w_kebabie"), 1, _line("opinia_szczur"))

func _make_order() -> void:
	if type.kind == &"owner":
		return
	order = [&"meat"]
	if type.kind == &"gourmet":
		order.append(&"rat")
	if randf() < 0.3:
		order.append(&"meat")
	if randf() < 0.6:
		order.append(&"salad")
	if randf() < 0.6:
		order.append(&"sauce")
	if randf() < 0.15:
		order.append(&"tortilla")
	strict = type.kind != &"gourmet" and order.size() > 1 and randf() < 0.3
	if strict:
		order.shuffle()

# Zamówienie powiedziane słowami postaci.
func _order_text() -> String:
	var words: Array[String] = []
	if strict:
		for id in order:
			words.append(Dialogs.ingredient(id))
		return _line("zamowienie_kolejnosc", {"lista": ", potem ".join(words)})
	for id in COUNTED:
		var amount := order.count(id)
		if id == &"meat" and amount > 1:
			words.append(Dialogs.ingredient("meat_2"))
		elif amount > 0:
			words.append(Dialogs.ingredient(id))
		elif id == &"salad" or id == &"sauce":
			words.append(Dialogs.ingredient("bez_" + str(id)))
	return _line("zamowienie", {"lista": ", ".join(words)})

func _rate(contents: Array[StringName]) -> void:
	var gourmet := type.kind == &"gourmet"
	if &"rat" in contents and not gourmet:
		rat_served.emit()
		served.emit(self, 0, false)
		if type.kind == &"sanepid":
			_fine()
		else:
			_leave(_line("szczur_w_kebabie"), 1, _line("opinia_szczur"))
		return
	if not &"meat" in contents:
		served.emit(self, 0, false)
		_leave(_line("bez_miesa"), 1, _line("opinia_bez_miesa"))
		return

	var mistakes := 0
	for id in COUNTED:
		mistakes += absi(contents.count(id) - order.count(id))
	var wrong_order := strict and mistakes == 0 and contents != order
	if wrong_order:
		mistakes = 1
	var price := BASE_PRICE + DOUBLE_MEAT_PRICE * (order.count(&"meat") - 1)
	var payment := maxi(price - mistakes * MISTAKE_COST, 0)
	if gourmet and &"rat" in contents:
		payment *= 2
	var reaction := ""
	if gourmet and not &"rat" in contents:
		reaction = _line("brak_wkladki")
		_opinion = _line("opinia_brak_wkladki")
		_stars = 2
	elif wrong_order:
		reaction = _line("zla_kolejnosc")
		_opinion = _line("opinie_ok")
		_stars = 3
	elif mistakes > 0:
		reaction = _line("pomylka")
		_opinion = _line("opinie_ok" if mistakes == 1 else "opinie_zle")
		_stars = 3 if mistakes == 1 else 2
	else:
		reaction = _line("dzieki")
		_opinion = _line("opinie_super")
		_stars = 4
		if time_left > _max_time * 0.5:
			payment += type.tip
			reaction += "\n" + _line("napiwek")
			_stars = 5
	if payment > 0:
		payment = maxi(payment + _bonus_tip, 0)

	fed = true
	served.emit(self, payment, payment > 0)
	if state == State.WAITING:
		if seat >= 0: # jest już przy stoliku
			_start_eating()
			_say(reaction)
		else:
			_leave(reaction, _stars, _opinion)
	else:
		_say(reaction) # poszedł do stolika

func _walk_to(target: Vector3) -> void:
	state = State.WALKING
	collision_layer = 0
	sprite.position.y = SPRITE_Y
	_path = [_aisle(global_position), _aisle(target), target]

func _walk(delta: float) -> void:
	if _path.is_empty():
		return
	_walk_time += delta
	sprite.position.y = SPRITE_Y + absf(sin(_walk_time * 9.0)) * 0.05
	global_position = global_position.move_toward(_path[0], SPEED * delta)
	if global_position.is_equal_approx(_path[0]):
		_path.pop_front()
		if _path.is_empty():
			_arrive()

func _arrive() -> void:
	sprite.position.y = SPRITE_Y
	if state == State.LEAVING:
		queue_free()
		return
	if state == State.ENTERING:
		_max_time = type.patience
		time_left = _max_time
		_say(_line("powitania"))
		_greeted = true
	collision_layer = _layer
	if seat >= 0:
		sprite.position.y = SEATED_SPRITE_Y
	if fed:
		_start_eating()
	else:
		state = State.WAITING

func _start_eating() -> void:
	state = State.EATING
	_timer = randf_range(12.0, 20.0)
	_say(_line("smacznego"))

func _wait(delta: float) -> void:
	time_left -= delta * drain
	if time_left <= 0.0:
		_leave(_line("rezygnacja"), 2 if type.kind == &"owner" else 1, _line("opinia_rezygnacja"))
	elif not _complained and time_left <= _max_time * 0.4:
		_complained = true
		_say(_line("ponaglenia"))

func _leave(text: String, stars: int, review: String) -> void:
	state = State.FAREWELL
	_timer = clampf(text.length() * 0.07, 2.5, 5.0)
	_bubble_time = 0.0
	bubble.text = text
	last_words = text
	collision_layer = 0
	if stars <= 1:
		Sfx.play_at(self, "angry")
	reviewed.emit(stars, review, display_name())

func _walk_out() -> void:
	# Od stolika najpierw w bok do przejścia, od lady tak samo.
	state = State.LEAVING
	_path = [_aisle(global_position), _door, _street]
	slot = -1
	seat = -1
	sprite.position.y = SPRITE_Y

func _aisle(point: Vector3) -> Vector3:
	return Vector3(AISLE_X, point.y, point.z)
