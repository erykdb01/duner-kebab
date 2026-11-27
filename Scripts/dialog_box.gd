extends CanvasLayer
# Twoje odpowiedzi w rozmowie (mysz albo klawisze 1-7), przyczepione obok klienta.
# Kwestie klienta są nad jego głową; tu ten sam styl tekstu na szarym gradiencie.

signal closed(customer: Node)

const Dialogs = preload("res://Scripts/dialogs.gd")
const Speech = preload("res://Scripts/speech.gd")
const HEAD_HEIGHT := 1.65 # tu patrzy gracz podczas rozmowy
const HOVER_COLOR := Color(1, 0.72, 0.3)
const GAP := 14.0 # odstęp od zdjęcia klienta
const BELOW_SPEECH := 0.3 # tyle metrów poniżej dymków zaczyna się lista

var player: Node
var notebook: Node
var customer: Node = null
var _actions: Array[Callable] = []

@onready var options: VBoxContainer = %Options
@onready var panel: PanelContainer = %Panel
@onready var gradient: GradientTexture2D = panel.get_theme_stylebox("panel").texture

func _ready() -> void:
	hide()

func open(target: Node) -> void:
	customer = target
	customer.talking = true
	show()
	player.set_busy(true)
	player.look_toward(customer.global_position + Vector3(0, HEAD_HEIGHT, 0))
	var greeting: Dictionary = customer.greet()
	if greeting.has("odpowiedzi"):
		_show_replies(greeting)
	else:
		_show_main()

func close() -> void:
	if not visible:
		return
	hide()
	var talked = customer # klient mógł już zniknąć
	customer = null
	player.set_busy(notebook.is_open())
	if is_instance_valid(talked):
		talked.talking = false
		closed.emit(talked)

# Gdy klient postanawia wyjść, rozmowa się kończy (pożegnanie widać nad głową).
func _process(_delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(customer) or customer.state == customer.State.FAREWELL \
			or customer.state == customer.State.LEAVING:
		close()
		return
	_place()

# Z prawej strony klienta, a gdy brakuje miejsca, z lewej; zawsze w granicach ekranu.
func _place() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var at: Vector3 = customer.global_position \
		+ Vector3(0, customer.speech.height - BELOW_SPEECH, 0)
	panel.visible = not camera.is_position_behind(at)
	if not panel.visible:
		return
	panel.reset_size()
	var side: Vector3 = camera.global_basis.x * customer.half_width()
	var right := camera.unproject_position(at + side)
	var left := camera.unproject_position(at - side)
	var view := get_viewport().get_visible_rect().size
	var area := panel.size
	var x := right.x + GAP
	var on_left := x + area.x > view.x and left.x - GAP - area.x >= 0.0
	if on_left:
		x = left.x - GAP - area.x
	# Gradient jest najmocniejszy od strony klienta.
	gradient.fill_from = Vector2(1, 0) if on_left else Vector2(0, 0)
	gradient.fill_to = Vector2(0, 0) if on_left else Vector2(1, 0)
	panel.position = Vector2(
		clampf(x, 0.0, maxf(view.x - area.x, 0.0)),
		clampf(right.y, 0.0, maxf(view.y - area.y, 0.0)))

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

# Cyfry działają tylko, gdy nie piszesz w notatniku.
func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
	var index: int = event.keycode - KEY_1
	if index >= 0 and index < _actions.size():
		get_viewport().set_input_as_handled()
		_actions[index].call()

# --- Widoki ---

func _show_main() -> void:
	var list := []
	if customer.can_take_order():
		var key := "powtorz" if customer.ordered else "zamowienie"
		list.append(_option(key, _ask_order))
	# O imię pyta się dopiero po zamówieniu (pani od Pimpka nie zamawia, więc od razu).
	if customer.ordered or customer.kind == &"owner":
		var name_key := "imie_znowu" if customer.name_known else "imie"
		list.append(_option(name_key, _ask_name))
	list.append(_option("pogadaj", _chat))
	if customer.kind == &"owner" and customer.state == customer.State.WAITING:
		list.append(_option("nie_widzialem", func(): customer.dismiss()))
	list.append(_throw_out_option({}))
	var end_key := "koniec_po" if customer.ordered else "koniec_przed"
	list.append(_option(end_key, close))
	_show(list)

# talk = {"odpowiedzi": [...], "wypros": {...}}
func _show_replies(talk: Dictionary) -> void:
	var list := []
	for reply in talk.get("odpowiedzi", []):
		list.append([str(reply.get("gracz", "...")), _reply.bind(reply, talk)])
	if list.is_empty():
		_show_main()
		return
	list.append(_throw_out_option(talk))
	_show(list)

# Wyproszenie pasujące do kwestii klienta, a gdy jej nie ma, losowe.
func _throw_out_option(talk: Dictionary) -> Array:
	var matched: Dictionary = talk.get("wypros", {})
	var action := func(): customer.throw_out(str(matched.get("klient", "")))
	if matched.has("gracz"):
		return [str(matched["gracz"]), action]
	return _option("wypros", action)

func _chat() -> void:
	if not customer.can_chat():
		customer.tired_of_chat()
		_show_main()
		return
	var talk: Dictionary = customer.next_conversation()
	customer.say(str(talk.get("klient", "...")))
	_show_replies(talk)

func _reply(reply: Dictionary, talk: Dictionary) -> void:
	customer.apply_reply(reply)
	if reply.has("dalej"):
		# Ciąg dalszy rozmowy: wyproszenie zostaje, chyba że odpowiedź ma własne.
		_show_replies({"odpowiedzi": reply["dalej"],
			"wypros": reply.get("wypros", talk.get("wypros", {}))})
	else:
		_show_main()

func _ask_order() -> void:
	customer.ask_order()
	_show_main()

func _ask_name() -> void:
	customer.ask_name()
	_show_main()

# Przycisk z losową kwestią gracza.
func _option(key: String, action: Callable) -> Array:
	return [Dialogs.player_line(customer.character, key), action]

# list = [[napis, akcja], ...]
func _show(list: Array) -> void:
	for button in options.get_children():
		options.remove_child(button)
		button.queue_free()
	_actions.clear()
	for entry in list:
		var action: Callable = entry[1]
		var button := Button.new()
		button.text = "%d. %s" % [_actions.size() + 1, entry[0]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		_style(button)
		button.pressed.connect(action, CONNECT_DEFERRED)
		options.add_child(button)
		_actions.append(action)
	_place()

# Sam tekst z obrysem, jak kwestie klienta; pod myszą zmienia kolor.
func _style(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.add_theme_font_size_override("font_size", Speech.FONT_SIZE)
	button.add_theme_color_override("font_color", Speech.TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", HOVER_COLOR)
	button.add_theme_color_override("font_pressed_color", HOVER_COLOR)
	button.add_theme_color_override("font_hover_pressed_color", HOVER_COLOR)
	button.add_theme_color_override("font_outline_color", Speech.OUTLINE_COLOR)
	button.add_theme_constant_override("outline_size", Speech.OUTLINE)
