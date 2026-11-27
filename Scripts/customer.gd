extends Area3D
# Klient: wchodzi, rozmawia i zamawia przy ladzie, czeka (zwykle przy stoliku), dostaje kebaba
# do ręki albo podchodzi zawołany po imieniu, płaci, czasem je i wychodzi.
# Zachowanie zależy od rodzaju (TYPES), teksty od postaci z Data/dialogi.json.
# W kolejce czeka dłużej; zbyt często drażniony wychodzi.

signal served(customer: Node, payment: int, may_sit: bool)
signal talk_requested(customer: Node)
signal fined
signal rat_served # kebab ze szczurem dla kogoś, kto go nie zamawiał
signal reviewed(stars: int, text: String, author: String)
signal pimpek_returned(customer: Node)

enum State { ENTERING, WAITING, WALKING, EATING, FAREWELL, LEAVING }

const Kebab = preload("res://Scripts/kebab.gd")
const Dialogs = preload("res://Scripts/dialogs.gd")
const Sfx = preload("res://Scripts/sfx.gd")
const Night = preload("res://Scripts/night.gd")
const Speech = preload("res://Scripts/speech.gd")
const PHOTO := "res://Textures/zdjecia/%s.%s"
const PHOTO_TYPES: Array[String] = ["png", "jpg", "webp"]
# Zdjęcia losowane według płci: te z głównego folderu (PHOTOS) i wszystkie z EXTRA_PHOTOS.
const PHOTOS := {
	"m": ["filozof", "gadula", "gbur", "poeta", "sanepid", "smakosz", "student", "teoretyk", "zwykly"],
	"k": ["babcia"],
}
const EXTRA_PHOTOS := "res://Textures/zdjecia/zwykli/%s/" # m albo k
const PHOTO_PIXELS := 64 # bok zdjęcia po rozpikselowaniu; mniej = większe piksele
const PHOTO_SIZE := 1.3 # bok kwadratu w metrach
const PHOTO_TOP := 1.95 # wysokość górnej krawędzi stojącego klienta
const HEAD_ROOM := 0.15 # z pionowego zdjęcia ucinana jest ta część nadmiaru u góry, reszta u dołu
# Ruchome zdjęcie: poziomy pasek kwadratowych klatek "nazwa_anim.png";
# opcjonalny "nazwa_anim.ogg" gra w pętli i idzie za klientem.
const ANIM_SUFFIX := "_anim"
const ANIM_FPS := 10.0
const MUSIC_VOLUME := -6.0 # w dB
const MUSIC_DISTANCE := 14.0 # dalej niż tyle metrów jej nie słychać
const MUSIC_GROUP := &"customer_music" # po tej grupie radio wie, kiedy się przyciszyć
# Postacie z własnym zdjęciem (nikt inny go nie dostaje).
const CHARACTER_LOOKS := {"kaseko": "res://Textures/zdjecia/kaseko_anim.png"}
const GIANT_LAYERS := 10 # tyle składników ma gigant (najwyżej MAX_LAYERS z prep_board.gd)
const GIANT_PRICE := 35 # zamiast BASE_PRICE
const SECRET_CHANCE := 0.12# zwykły klient po cichu zamawia żywego szczura
const DEFAULT_NERVES := 3 # po tylu irytacjach wychodzi ("nerwy" w dialogi.json)
const QUEUE_DRAIN := 0.5 # w kolejce cierpliwość ubywa wolniej
const QUEUE_COMPLAINT := 40.0 # co tyle sekund w kolejce narzeka
const SPEED := 1.6
const AISLE_X := 0.5 # przejście wzdłuż lady
const BASE_PRICE := 20
const DOUBLE_MEAT_PRICE := 5
const MISTAKE_COST := 8
const COUNTED: Array[StringName] = [&"meat", &"rat", &"salad", &"sauce", &"tortilla"]
const SPRITE_Y := 0.88
const SEAT_HEIGHT := 0.52 # siedzisko krzesła; dół zdjęcia siedzącego klienta
const FOOD_PATIENCE := 1.8 # po przyjęciu zamówienia czeka dłużej
const REPEAT_COST := 8.0 # sekundy cierpliwości za prośbę o powtórzenie
const MAX_CHATS := 2
const FRONT_WALL_Z := -5.0
# "typ" postaci -> [zachowanie, cierpliwość w sekundach, napiwek w zł]
const TYPES := {
	&"regular": [&"regular", 75.0, 5],
	&"charakter": [&"regular", 75.0, 5],
	&"student": [&"regular", 55.0, 8],
	&"babcia": [&"regular", 110.0, 2],
	&"sanepid": [&"sanepid", 75.0, 5],
	&"smakosz": [&"gourmet", 90.0, 10],
	&"wlasciciel": [&"owner", 110.0, 0],
	&"kaseko": [&"regular", 150.0, 15],
}

static var _photos := {} # gotowe klatki zdjęć, żeby nie przerabiać ich przy każdym wejściu

var kind := &"regular" # regular, sanepid, gourmet, owner
var patience := 75.0
var tip := 5
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
var secret := false # chce po cichu żywego szczura w kebabie
var giant := false # zamawia gigantycznego kebaba
var queued := false # ktoś, kto przyszedł wcześniej, jeszcze czeka (ustawia game.gd)
var gender := "m"
var look := "" # ścieżka wylosowanego zdjęcia
var _frames: Array = [] # tekstury zdjęcia; więcej niż jedna = animacja
var _anim_time := 0.0
var _music: AudioStreamPlayer3D
var _annoyance := 0
var _queue_time := 0.0
var chats := 0
var speech := Speech.new() # wypowiedzi nad głową
var _greeting := {}
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
var _walk_time := 0.0
var _complained := false
var _opinion := ""
var _stars := 3

@onready var sprite: Sprite3D = $Sprite3D
@onready var _layer := collision_layer

func _ready() -> void:
	collision_layer = 0
	speech.target = self
	add_child(speech)

# Wywołać po dodaniu do sceny.
func start(type_id: StringName, new_character: String, new_gender: String, new_name: String,
		new_slot: int, street: Vector3, door: Vector3, counter: Vector3) -> void:
	var stats: Array = TYPES[type_id]
	kind = stats[0]
	giant = type_id == &"kaseko"
	patience = stats[1]
	tip = stats[2]
	character = new_character
	gender = new_gender
	first_name = new_name
	_set_look()
	slot = new_slot
	_street = street
	_door = door
	global_position = street
	_path = [door, _aisle(counter), counter]
	_conversations = Dialogs.conversations(character)
	_greeting = Dialogs.greeting(character)
	_make_order()

func _process(delta: float) -> void:
	sprite.modulate = Night.tint(global_position)
	_animate(delta)
	speech.height = sprite.position.y + PHOTO_TOP - SPRITE_Y + 0.12
	speech.pinned = talking
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
	if kind == &"owner" and player.held.is_in_group("pimpek"):
		return "[E] Oddaj Pimpka"
	return "[E] Daj szczura" if player.held.is_in_group("rat") else "Klient tego nie chce"

func interact(player) -> void:
	if not player.held:
		if state == State.WAITING or state == State.EATING:
			talk_requested.emit(self)
		return
	if state != State.WAITING:
		return
	if kind == &"owner":
		_owner_takes(player)
	elif player.held.is_in_group("rat"):
		player.discard()
		served.emit(self, 0, false)
		if wants_rat():
			_leave(_line("surowy_szczur"), 2, _line("opinia_surowy_szczur"))
		elif kind == &"sanepid":
			_fine()
		else:
			_leave(_line("szczur_do_reki"), 1, _line("opinia_szczur"))
	elif player.held is Kebab:
		if not ordered:
			say(_line("nie_zamowione"))
			return
		var contents: Array[StringName] = player.held.contents
		player.discard()
		_rate(contents)

# --- Rozmowa (wywoływane przez okno dialogu) ---

func display_name() -> String:
	return first_name if name_known else str(Dialogs.character(character).get("tytul", "Klient"))

func say(text: String) -> void:
	speech.say(text)

# Połowa szerokości zdjęcia w metrach (obok niej stają przyciski rozmowy).
func half_width() -> float:
	return sprite.texture.get_width() * sprite.pixel_size / 2.0 if sprite.texture else 0.4

# Początek rozmowy. Zwraca powitanie, jeśli można na nie odpowiedzieć (przy pierwszej rozmowie).
func greet() -> Dictionary:
	if state == State.EATING:
		say(_line("smacznego"))
		return {}
	if _greeted:
		say(_line("czekam"))
		return {}
	_greeted = true
	say(str(_greeting.get("klient", "...")))
	return _greeting

# "reaction" to odpowiedź na wyproszenie pasujące do rozmowy.
func throw_out(reaction := "") -> void:
	_leave(reaction if reaction else _line("wyproszony"), 1, _line("opinia_wyproszony"))

func can_take_order() -> bool:
	return kind != &"owner" and state == State.WAITING

func ask_order() -> void:
	if not ordered:
		ordered = true
		_max_time = patience * FOOD_PATIENCE
		time_left = _max_time
		_complained = false
		say(_order_text())
		return
	time_left = maxf(time_left - REPEAT_COST, 5.0)
	say(_line("powtorka", {"zamowienie": _order_text()}))
	_annoy()

# Pierwsze pytanie o imię jest w porządku, kolejne drażnią.
func ask_name() -> void:
	var again := name_known
	name_known = true
	say(_line("imie", {"imie": first_name}))
	if again:
		_annoy()

func can_chat() -> bool:
	return chats < MAX_CHATS and not _conversations.is_empty()

func next_conversation() -> Dictionary:
	chats += 1
	return Dialogs.take(_conversations)

func tired_of_chat() -> void:
	say(_line("dosc_gadania"))
	_annoy()

# Reakcja i skutki wybranej odpowiedzi.
func apply_reply(reply: Dictionary) -> void:
	var reaction := str(reply.get("klient", ""))
	say(reaction)
	_bonus_tip += int(reply.get("napiwek", 0))
	var seconds := float(reply.get("cierpliwosc", 0))
	if state == State.WAITING and seconds != 0.0:
		time_left = clampf(time_left + seconds, 5.0, _max_time)
	if reply.get("wychodzi", false) and state == State.WAITING:
		_leave(reaction, 1, _line("obrazony"))
	elif seconds < 0.0:
		_annoy(2 if seconds <= -20.0 else 1)

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
		say(_line("po_zamowieniu"))

# Zawołany po imieniu: wraca do lady.
func come_to_counter(new_slot: int, counter: Vector3) -> void:
	slot = new_slot
	seat = -1
	called = true
	_walk_to(counter)
	say(_line("zawolany"))

func say_already_here() -> void:
	say(_line("juz_stoje"))

func is_hungry() -> bool:
	return not fed and (state == State.WAITING or state == State.WALKING)

# --- Szczury i światło ---

# Czy klient jest w lokalu i może się przejąć szczurem.
func can_see_rat() -> bool:
	if wants_rat() or kind == &"owner":
		return false
	return state != State.FAREWELL and state != State.LEAVING and global_position.z > FRONT_WALL_Z

func wants_rat() -> bool:
	return kind == &"gourmet" or secret

func see_rat() -> void:
	if kind == &"sanepid":
		_fine()
	else:
		_leave(_line("widzi_szczura"), 1, _line("opinia_widzial_szczura"))

# --- Wewnętrzne ---

# Zdjęcia z własnych folderów zwykłych klientów (bez nich nie przychodzą zwykłe klientki).
static func extra_photos(of_gender: String) -> Array[String]:
	var folder := EXTRA_PHOTOS % of_gender
	var paths: Array[String] = []
	for file in ResourceLoader.list_directory(folder):
		if file.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"]:
			paths.append(folder + file)
	return paths

# Wygląd: chodzące kwadratowe zdjęcie. Nie jest przypisane do osoby: losowe spośród zdjęć
# jej płci, w miarę możliwości inne niż u klientów, którzy już są.
func _set_look() -> void:
	if CHARACTER_LOOKS.has(character):
		_show_look(CHARACTER_LOOKS[character])
		return
	var paths := extra_photos(gender)
	for id in PHOTOS[gender]:
		for extension in PHOTO_TYPES:
			var path := PHOTO % [id, extension]
			if ResourceLoader.exists(path):
				paths.append(path)
	if paths.is_empty():
		return
	var taken := get_tree().get_nodes_in_group("customers").map(
		func(other): return other.look)
	var fresh := paths.filter(func(path): return not path in taken)
	_show_look((fresh if fresh else paths).pick_random())

func _show_look(path: String) -> void:
	look = path
	_frames = _photo(look)
	sprite.texture = _frames[0]
	sprite.pixel_size = PHOTO_SIZE / PHOTO_PIXELS
	sprite.offset.y = (PHOTO_TOP - PHOTO_SIZE / 2.0 - SPRITE_Y) / sprite.pixel_size
	_start_music(look.get_basename() + ".ogg")

# Klatki zdjęcia: zwykłe daje jedną, pasek "_anim" wszystkie po kolei.
func _photo(path: String) -> Array:
	if not _photos.has(path):
		var image: Image = load(path).get_image()
		if image.is_compressed():
			image.decompress()
		var frames: Array = []
		if path.get_basename().ends_with(ANIM_SUFFIX):
			var side := image.get_height()
			for index in image.get_width() / side:
				frames.append(_square(image, Rect2i(index * side, 0, side, side)))
		else:
			var side := mini(image.get_width(), image.get_height())
			frames.append(_square(image, Rect2i((image.get_width() - side) / 2,
				int((image.get_height() - side) * HEAD_ROOM), side, side)))
		_photos[path] = frames
	return _photos[path]

# Wycina kwadrat i zmniejsza, żeby było widać piksele.
func _square(image: Image, region: Rect2i) -> Texture2D:
	var part := image.get_region(region)
	part.resize(PHOTO_PIXELS, PHOTO_PIXELS, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(part)

# Muzyka należąca do zdjęcia: dziecko klienta, więc chodzi razem z nim i znika, gdy wyjdzie.
func _start_music(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStreamOggVorbis = load(path)
	stream.loop = true
	_music = AudioStreamPlayer3D.new()
	_music.stream = stream
	_music.volume_db = MUSIC_VOLUME
	_music.unit_size = 2.5
	_music.max_distance = MUSIC_DISTANCE
	_music.position.y = 1.4
	_music.bus = &"Muzyka"
	_music.add_to_group(MUSIC_GROUP)
	add_child(_music)
	_music.play()

# Przy muzyce klatka wynika z miejsca w nagraniu, żeby obraz się nie rozjeżdżał z dźwiękiem.
func _animate(delta: float) -> void:
	if _frames.size() < 2:
		return
	_anim_time += delta
	if _music and _music.playing:
		_anim_time = _music.get_playback_position()
	sprite.texture = _frames[int(_anim_time * ANIM_FPS) % _frames.size()]

func _line(key: String, values := {}) -> String:
	return Dialogs.line(character, key, values)

func _fine() -> void:
	fined.emit()
	_leave(_line("mandat"), 1, _line("opinia_widzial_szczura"))

func _owner_takes(player) -> void:
	if player.held.is_in_group("pimpek"):
		pimpek_returned.emit(self)
		player.discard()
		_leave(_line("pimpek_oddany"), 5, _line("opinie_super"))
	elif player.held.is_in_group("rat"):
		say(_line("nie_pimpek"))
	elif player.held is Kebab:
		if not &"rat" in player.held.contents:
			say(_line("nie_glodna"))
			return
		player.discard()
		rat_served.emit()
		served.emit(self, 0, false)
		_leave(_line("pimpek_w_kebabie"), 1, _line("opinia_szczur"))

func _make_order() -> void:
	if kind == &"owner":
		return
	if giant:
		_make_giant_order()
		return
	order = [&"meat"]
	# Tylko zwykli klienci bez własnej postaci; sanepid nigdy o to nie prosi.
	secret = kind == &"regular" and Dialogs.character(character).is_empty() \
		and randf() < SECRET_CHANCE
	if wants_rat():
		order.append(&"rat")
	if randf() < 0.3:
		order.append(&"meat")
	if randf() < 0.6:
		order.append(&"salad")
	if randf() < 0.6:
		order.append(&"sauce")
	if randf() < 0.15:
		order.append(&"tortilla")
	strict = not wants_rat() and order.size() > 1 and randf() < 0.3
	if strict:
		order.shuffle()

# Gigant: 2-3 porcje mięsa, reszta to surówka, sos i najwyżej 2 dodatkowe tortille.
# Kolejność się nie liczy.
func _make_giant_order() -> void:
	order = [&"meat", &"meat", &"salad", &"sauce"]
	if randf() < 0.5:
		order.append(&"meat")
	while order.size() < GIANT_LAYERS:
		var extra: StringName = [&"salad", &"sauce", &"tortilla"].pick_random()
		if extra != &"tortilla" or order.count(extra) < 2:
			order.append(extra)

# Zamówienie powiedziane słowami postaci.
func _order_text() -> String:
	var words: Array[String] = []
	if strict:
		for id in order:
			words.append(Dialogs.ingredient(id))
		return _line("zamowienie_kolejnosc", {"lista": ", potem ".join(words)})
	# Tylko to, co ma być w środku: "mięso, surówka i sos".
	for id in COUNTED:
		var amount := order.count(id)
		if giant and amount > 1:
			# U giganta liczy się dokładna liczba: "3× mięso".
			words.append("%d× %s" % [amount, Kebab.NAMES[id]])
		elif id == &"meat" and amount > 1:
			words.append(Dialogs.ingredient("meat_2"))
		elif amount > 0:
			words.append(Dialogs.ingredient(id))
	var last: String = words.pop_back()
	var list := "%s i %s" % [", ".join(words), last] if words else last
	return _line("zamowienie_po_cichu" if secret else "zamowienie", {"lista": list})

func _rate(contents: Array[StringName]) -> void:
	var wanted_rat := wants_rat()
	if &"rat" in contents and not wanted_rat:
		rat_served.emit()
		served.emit(self, 0, false)
		if kind == &"sanepid":
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
	var base := GIANT_PRICE if giant else BASE_PRICE
	var price := base + DOUBLE_MEAT_PRICE * (order.count(&"meat") - 1)
	var payment := maxi(price - mistakes * MISTAKE_COST, 0)
	if wanted_rat and &"rat" in contents:
		payment *= 2
	var reaction := ""
	if wanted_rat and not &"rat" in contents:
		reaction = _line("brak_szczura")
		_opinion = _line("opinia_brak_szczura")
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
			payment += tip
			reaction += "\n" + _line("napiwek")
			_stars = 5
	if payment > 0:
		payment = maxi(payment + _bonus_tip, 0)

	fed = true
	served.emit(self, payment, payment > 0)
	if state == State.WAITING:
		if seat >= 0: # jest już przy stoliku
			_start_eating()
			say(reaction)
		else:
			_leave(reaction, _stars, _opinion)
	else:
		say(reaction) # poszedł do stolika

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
		_max_time = patience
		time_left = _max_time
		say(str(_greeting.get("klient", "...")))
	collision_layer = _layer
	if seat >= 0:
		sprite.position.y = _seated_y()
	if fed:
		_start_eating()
	else:
		state = State.WAITING

# Wysokość sprite'a, przy której dół zdjęcia leży na siedzisku.
func _seated_y() -> float:
	if not sprite.texture:
		return SPRITE_Y
	var bottom := (sprite.offset.y - sprite.texture.get_height() / 2.0) * sprite.pixel_size
	return SEAT_HEIGHT - global_position.y - bottom

func _start_eating() -> void:
	state = State.EATING
	_timer = randf_range(12.0, 20.0)
	say(_line("smacznego"))

func _wait(delta: float) -> void:
	time_left -= delta * (QUEUE_DRAIN if queued else 1.0)
	if queued:
		_queue_time += delta
		if _queue_time >= QUEUE_COMPLAINT:
			_queue_time = 0.0
			say(_line("ponaglenia_kolejka"))
	if time_left <= 0.0:
		_leave(_line("rezygnacja"), 2 if kind == &"owner" else 1, _line("opinia_rezygnacja"))
	elif not _complained and time_left <= _max_time * 0.4:
		_complained = true
		say(_line("ponaglenia"))

# Irytacja czekającego klienta: przy przedostatniej ostrzega, przy ostatniej wychodzi.
func _annoy(amount := 1) -> void:
	if state != State.WAITING:
		return
	_annoyance += amount
	var nerves := int(Dialogs.character(character).get("nerwy", DEFAULT_NERVES))
	if _annoyance >= nerves:
		_leave(_line("zdenerwowany"), 1, _line("opinia_zdenerwowany"))
	elif _annoyance == nerves - 1:
		say(_line("ostrzezenie"))

func _leave(text: String, stars: int, review: String) -> void:
	state = State.FAREWELL
	_timer = clampf(text.length() * 0.07, 2.5, 5.0)
	say(text)
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
