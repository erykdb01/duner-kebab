extends CanvasLayer
# Twoje odpowiedzi w rozmowie (mysz albo klawisze 1-7). Kwestie klienta są nad jego głową.

signal closed(customer: Node)

const Dialogs = preload("res://Scripts/dialogs.gd")
const HEAD_HEIGHT := 1.85 # tu patrzy gracz podczas rozmowy

var player: Node
var notebook: Node
var customer: Node = null
var _actions: Array[Callable] = []

@onready var options: VBoxContainer = %Options

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
	var name_key := "imie_znowu" if customer.name_known else "imie"
	list.append(_option(name_key, _ask_name))
	list.append(_option("pogadaj", _chat))
	if customer.kind == &"owner" and customer.state == customer.State.WAITING:
		list.append(_option("nie_widzialem", func(): customer.dismiss()))
	list.append(_option("wypros", func(): customer.throw_out()))
	var end_key := "koniec_po" if customer.ordered else "koniec_przed"
	list.append(_option(end_key, close))
	_show(list)

# talk = {"co": wyjaśnienie, "odpowiedzi": [...]}
func _show_replies(talk: Dictionary, explained := false) -> void:
	var list := []
	for reply in talk.get("odpowiedzi", []):
		list.append([str(reply.get("gracz", "...")), _reply.bind(reply)])
	if list.is_empty():
		_show_main()
		return
	if not explained:
		list.append(_option("co", _ask_what.bind(talk)))
	list.append(_option("wypros", func(): customer.throw_out()))
	_show(list)

func _ask_what(talk: Dictionary) -> void:
	customer.explain(talk)
	_show_replies(talk, true)

func _chat() -> void:
	if not customer.can_chat():
		customer.say(customer.tired_of_chat())
		_show_main()
		return
	var talk: Dictionary = customer.next_conversation()
	customer.say(str(talk.get("klient", "...")))
	_show_replies(talk)

func _reply(reply: Dictionary) -> void:
	customer.apply_reply(reply)
	if reply.has("dalej"):
		# Ciąg dalszy: te same zasady, "Co?" powtarza ostatnią kwestię.
		var more := {"co": reply.get("co", reply.get("klient", "...")), "odpowiedzi": reply["dalej"]}
		_show_replies(more)
	else:
		_show_main()

func _ask_order() -> void:
	customer.say(customer.ask_order())
	_show_main()

func _ask_name() -> void:
	customer.say(customer.ask_name())
	_show_main()

# Przycisk z losową kwestią gracza.
func _option(key: String, action: Callable) -> Array:
	return [Dialogs.player_line(key), action]

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
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(action, CONNECT_DEFERRED)
		options.add_child(button)
		_actions.append(action)
