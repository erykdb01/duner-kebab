extends CanvasLayer
# Minigra na refleks: wciskaj po kolei pokazane klawisze (WASD albo strzałki), każdy na czas.
# Użycie: dodać do sceny, podłączyć "done", wywołać start(). Węzeł sam potem znika.

signal done(success: bool)

const Speech = preload("res://Scripts/speech.gd")
const KEYS := {KEY_W: "W", KEY_A: "A", KEY_S: "S", KEY_D: "D"}
const ARROWS := {KEY_UP: KEY_W, KEY_LEFT: KEY_A, KEY_DOWN: KEY_S, KEY_RIGHT: KEY_D}
const DONE_COLOR := Color(0.4, 0.95, 0.4)
const NOW_COLOR := Color(1, 0.72, 0.3)
const LATER_COLOR := Color(0.55, 0.55, 0.6)

var _sequence: Array[int] = []
var _letters: Array[Label] = []
var _next := 0
var _per_key := 1.0
var _left := 1.0
var _bar := ProgressBar.new()

func start(title: String, length: int, per_key: float) -> void:
	layer = 9
	_per_key = per_key
	_left = per_key
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.09, 0.94)
	style.border_color = NOW_COLOR
	style.set_border_width_all(3)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	column.add_child(_label(title, 24))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	column.add_child(row)
	for i in length:
		var key: int = KEYS.keys().pick_random()
		_sequence.append(key)
		var letter := _label(KEYS[key], 44)
		letter.custom_minimum_size.x = 48
		row.add_child(letter)
		_letters.append(letter)
	_bar.max_value = per_key
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(360, 14)
	column.add_child(_bar)
	_refresh()

func _process(delta: float) -> void:
	if _sequence.is_empty():
		return
	_left -= delta
	_bar.value = _left
	if _left <= 0.0:
		_finish(false)

func _input(event: InputEvent) -> void:
	if _sequence.is_empty() or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = ARROWS.get(event.physical_keycode, event.physical_keycode)
	if not KEYS.has(key):
		return
	get_viewport().set_input_as_handled()
	if key != _sequence[_next]:
		_finish(false)
		return
	_next += 1
	_left = _per_key
	if _next == _sequence.size():
		_finish(true)
	else:
		_refresh()

func _finish(success: bool) -> void:
	_sequence.clear()
	done.emit(success)
	queue_free()

func _refresh() -> void:
	for i in _letters.size():
		_letters[i].modulate = DONE_COLOR if i < _next else (NOW_COLOR if i == _next else LATER_COLOR)

func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Speech.OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", Speech.OUTLINE)
	return label
