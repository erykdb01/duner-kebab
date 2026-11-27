extends CenterContainer
# Okno ustawień ekranu i dźwięku (menu i pauza). Wybór zapisuje się w user://ustawienia.cfg.

signal closed

const PATH := "user://ustawienia.cfg"
# [szyna z default_bus_layout.tres, podpis suwaka]
const VOLUMES: Array = [
	[&"Master", "Głośność ogólna"],
	[&"Muzyka", "Muzyka (radio i Kaseko)"],
]
const SIZES: Array[Vector2i] = [
	Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900),
	Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160),
]

static var _applied := false

var _sizes: Array[Vector2i] = []
var _list := OptionButton.new()
var _fullscreen := CheckButton.new()
var _close := Button.new()
var _sliders := {} # szyna -> suwak 0..100

# Zapisane ustawienia; wystarczy raz po uruchomieniu gry.
static func apply_saved() -> void:
	if _applied:
		return
	_applied = true
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	for entry in VOLUMES:
		apply_volume(entry[0], config.get_value("dzwiek", entry[0], 100.0))
	# Sam suwak głośności nie zmienia ekranu.
	if config.has_section("ekran"):
		apply(config.get_value("ekran", "rozdzielczosc", Vector2i(1152, 648)),
			config.get_value("ekran", "pelny", false))

# "percent" 0..100; 100 to głośność z projektu, 0 wycisza.
static func apply_volume(bus: StringName, percent: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, percent <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(percent, 1.0) / 100.0))

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
	for entry in VOLUMES:
		box.add_child(_label(entry[1], 20))
		var slider := HSlider.new()
		slider.max_value = 100.0
		slider.step = 5.0
		slider.custom_minimum_size.y = 20.0
		slider.value_changed.connect(_change_volume.bind(entry[0]))
		box.add_child(slider)
		_sliders[entry[0]] = slider
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
	for bus in _sliders:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			var muted := AudioServer.is_bus_mute(index)
			_sliders[bus].set_value_no_signal(
				0.0 if muted else db_to_linear(AudioServer.get_bus_volume_db(index)) * 100.0)

func _change_volume(percent: float, bus: StringName) -> void:
	apply_volume(bus, percent)
	_save("dzwiek", {bus: percent})

# Dopisuje do pliku, nie kasując pozostałych ustawień.
func _save(section: String, values: Dictionary) -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	for key in values:
		config.set_value(section, key, values[key])
	config.save(PATH)

func _change() -> void:
	if _list.selected < 0:
		return
	var resolution := _sizes[_list.selected]
	var full := _fullscreen.button_pressed
	apply(resolution, full)
	_list.disabled = full
	_save("ekran", {"rozdzielczosc": resolution, "pelny": full})

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label
