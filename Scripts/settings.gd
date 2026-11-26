extends CenterContainer
# Okno ustawień ekranu (menu i pauza). Wybór zapisuje się w user://ustawienia.cfg.

signal closed

const PATH := "user://ustawienia.cfg"
const SIZES: Array[Vector2i] = [
	Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900),
	Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160),
]

static var _applied := false

var _sizes: Array[Vector2i] = []
var _list := OptionButton.new()
var _fullscreen := CheckButton.new()
var _close := Button.new()

# Zapisane ustawienia; wystarczy raz po uruchomieniu gry.
static func apply_saved() -> void:
	if _applied:
		return
	_applied = true
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		apply(config.get_value("ekran", "rozdzielczosc", Vector2i(1152, 648)),
			config.get_value("ekran", "pelny", false))

static func apply(resolution: Vector2i, fullscreen: bool) -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(resolution)
	# Okno na środek ekranu.
	var area := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	DisplayServer.window_set_position(area.position + (area.size - resolution).max(Vector2i.ZERO) / 2)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.07, 0.96)
	style.set_border_width_all(3)
	style.border_color = Color(1, 0.62, 0.3)
	style.set_content_margin_all(22.0)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 420.0
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_label("USTAWIENIA", 30))
	box.add_child(_label("Rozdzielczość okna", 20))
	box.add_child(_list)
	_fullscreen.text = "Pełny ekran (rozdzielczość monitora)"
	box.add_child(_fullscreen)
	_close.text = "Wróć"
	box.add_child(_close)
	_list.item_selected.connect(func(_index): _change())
	_fullscreen.toggled.connect(func(_on): _change())
	_close.pressed.connect(close)
	hide()

func open() -> void:
	_refresh()
	show()
	_close.grab_focus()

func close() -> void:
	hide()
	closed.emit()

# Pokazuje obecny stan okna; na liście tylko rozmiary mieszczące się na ekranie.
func _refresh() -> void:
	var screen := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var current := DisplayServer.window_get_size()
	var mode := DisplayServer.window_get_mode()
	var full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	_sizes.assign(SIZES.filter(func(fit): return fit.x <= screen.x and fit.y <= screen.y))
	if not full and not current in _sizes:
		_sizes.append(current)
	_list.clear()
	for entry in _sizes:
		_list.add_item("%d x %d" % [entry.x, entry.y])
	_list.select(maxi(_sizes.find(current), 0))
	_list.disabled = full
	_fullscreen.set_pressed_no_signal(full)

func _change() -> void:
	if _list.selected < 0:
		return
	var resolution := _sizes[_list.selected]
	var full := _fullscreen.button_pressed
	apply(resolution, full)
	_list.disabled = full
	var config := ConfigFile.new()
	config.set_value("ekran", "rozdzielczosc", resolution)
	config.set_value("ekran", "pelny", full)
	config.save(PATH)

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label
