extends CanvasLayer
# Minigra na refleks: wciskaj po kolei pokazane klawisze (WASD albo strzałki), każdy na czas.
# Użycie: dodać do sceny, podłączyć "done", wywołać start(). Węzeł sam potem znika.

signal done(success: bool)

const Ui = preload("res://Scripts/pixel_ui.gd")
const KEYS := {KEY_W: "W", KEY_A: "A", KEY_S: "S", KEY_D: "D"}
const ARROWS := {KEY_UP: KEY_W, KEY_LEFT: KEY_A, KEY_DOWN: KEY_S, KEY_RIGHT: KEY_D}

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
	center.theme = Ui.theme()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Ui.frame(Ui.BACK, Ui.ACCENT, 20.0))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading := Ui.label(22, title)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	column.add_child(row)
	for i in length:
		var key: int = KEYS.keys().pick_random()
		_sequence.append(key)
		var letter := Ui.label(44, KEYS[key])
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.custom_minimum_size.x = 48
		row.add_child(letter)
		_letters.append(letter)
	_bar.max_value = per_key
	_bar.step = 0.01
	Ui.bar(column, _bar)
	var fill: StyleBoxFlat = _bar.get_theme_stylebox("fill")
	fill.bg_color = Ui.WARN
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
		_letters[i].add_theme_color_override("font_color",
			Ui.GOOD if i < _next else (Ui.ACCENT if i == _next else Ui.DIM))
