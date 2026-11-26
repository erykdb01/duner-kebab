extends CanvasLayer
# Rozmowa z klientem: jego kwestia i odpowiedzi do wyboru (mysz albo klawisze 1-6).

signal closed(customer: Node)

const Dialogs = preload("res://Scripts/dialogs.gd")

var player: Node
var notebook: Node
var customer: Node = null
var _actions: Array[Callable] = []
var _over := false # klient skończył rozmowę i wychodzi

@onready var speaker: Label = %Speaker
@onready var words: Label = %Words
@onready var options: VBoxContainer = %Options

func _ready() -> void:
	hide()

func open(target: Node) -> void:
	customer = target
	customer.talking = true
	_over = false
	show()
	player.set_busy(true)
	_show_main(customer.greet())

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

func _process(_delta: float) -> void:
	if not visible or _over:
		return
	if not is_instance_valid(customer):
		close()
	elif customer.state == customer.State.FAREWELL or customer.state == customer.State.LEAVING:
		_show_end(customer.last_words)

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

func _show_main(text: String) -> void:
	var list := []
	var is_owner: bool = customer.type.kind == &"owner"
	if customer.can_take_order():
		var key := "powtorz" if customer.ordered else "zamowienie"
		list.append(_option(key, func(said): _answer(said, customer.ask_order())))
	var name_key := "imie_znowu" if customer.name_known else "imie"
	list.append(_option(name_key, func(said): _answer(said, customer.ask_name())))
	list.append(_option("pogadaj", _chat))
	if is_owner and customer.state == customer.State.WAITING:
		list.append(_option("nie_widzialem", func(_said): customer.dismiss()))
	var end_key := "koniec_po" if customer.ordered else "koniec_przed"
	list.append(_option(end_key, func(_said): close()))
	_show(text, list)

func _chat(said: String) -> void:
	if not customer.can_chat():
		_answer(said, customer.tired_of_chat())
		return
	var talk: Dictionary = customer.next_conversation()
	_show_replies(_quote(said, str(talk.get("klient", "..."))), talk.get("odpowiedzi", []))

func _show_replies(text: String, replies: Array) -> void:
	var list := []
	for reply in replies:
		list.append([str(reply.get("gracz", "...")), _reply.bind(reply)])
	if list.is_empty():
		_show_main(text)
		return
	_show(text, list)

func _reply(reply: Dictionary) -> void:
	var text := _quote(str(reply.get("gracz", "...")), customer.apply_reply(reply))
	if customer.state == customer.State.FAREWELL:
		_show_end(text)
	elif reply.has("dalej"):
		_show_replies(text, reply["dalej"])
	else:
		_show_main(text)

func _answer(said: String, answer: String) -> void:
	_show_main(_quote(said, answer))

func _show_end(text: String) -> void:
	_over = true
	_show(text, [_option("koniec", func(_said): close())])

# Przycisk z losową kwestią gracza; akcja dostaje wypowiedziany tekst.
func _option(key: String, action: Callable) -> Array:
	var text := Dialogs.player_line(key)
	return [text, action.bind(text)]

func _quote(said: String, answer: String) -> String:
	return "Ty: %s\n\n%s" % [said, answer]

# list = [[napis, akcja], ...]
func _show(text: String, list: Array) -> void:
	speaker.text = customer.display_name()
	words.text = text
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
