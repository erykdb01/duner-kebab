extends CanvasLayer
# Notatnik gracza (Tab), kartka z notatkami na ekranie i wołanie klienta po imieniu (Q).
# Gra nie podpowiada zamówień: jest tylko to, co zapiszesz.

signal shouted(text: String)

const STICKY_LINES := 12

var player: Node
var dialog: Node

@onready var sticky: Control = %Sticky
@onready var sticky_text: Label = %StickyText
@onready var pad: Control = %Pad
@onready var pad_text: TextEdit = %PadText
@onready var shout: Control = %Shout
@onready var shout_line: LineEdit = %ShoutLine

func _ready() -> void:
	pad.hide()
	shout.hide()
	pad_text.text_changed.connect(_refresh_sticky)
	shout_line.text_submitted.connect(_on_shout)
	_refresh_sticky()

func is_open() -> bool:
	return pad.visible or shout.visible

func close() -> void:
	if not is_open():
		return
	pad.hide()
	shout.hide()
	pad_text.release_focus()
	shout_line.release_focus()
	_refresh_sticky()
	player.set_busy(dialog.visible)

# _input, żeby Tab i Esc nie trafiły do pola tekstowego.
func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if is_open():
		if event.is_action_pressed("ui_cancel") or (pad.visible and event.is_action_pressed("notes")):
			get_viewport().set_input_as_handled()
			close()
	elif event.is_action_pressed("notes") and (not player.busy or dialog.visible):
		get_viewport().set_input_as_handled()
		_open_pad()
	elif event.is_action_pressed("shout") and not player.busy:
		get_viewport().set_input_as_handled()
		_open_shout()

func _open_pad() -> void:
	pad.show()
	sticky.hide()
	player.set_busy(true)
	pad_text.grab_focus()
	# Kursor na koniec, żeby od razu dopisywać.
	pad_text.set_caret_line(pad_text.get_line_count() - 1)
	pad_text.set_caret_column(pad_text.get_line(pad_text.get_line_count() - 1).length())

func _open_shout() -> void:
	shout.show()
	shout_line.clear()
	player.set_busy(true)
	shout_line.grab_focus()
	shout_line.edit.call_deferred()

func _on_shout(text: String) -> void:
	close()
	if not text.strip_edges().is_empty():
		shouted.emit(text.strip_edges())

# Kartka w rogu pokazuje ostatnie linie notatek.
func _refresh_sticky() -> void:
	var lines := pad_text.text.strip_edges().split("\n", false)
	var start := maxi(lines.size() - STICKY_LINES, 0)
	sticky_text.text = "\n".join(lines.slice(start))
	sticky.visible = not pad.visible and not lines.is_empty()
