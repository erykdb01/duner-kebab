extends CanvasLayer
# Wypowiedzi klienta nad jego głową, jedna nad drugą (najnowsza na dole).
# Rysowane na ekranie, nie w 3D, więc filtr pikseli ich nie rozmywa.

const MAX_LINES := 3
const MAX_WIDTH := 360.0
const FONT_SIZE := 19
const RANGE := 11.0
const MARGIN := 8.0

var target: Node3D
var height := 1.95
var pinned := false # w trakcie rozmowy teksty nie znikają
var _entries: Array[Dictionary] = []
var _box := VBoxContainer.new()
var _style := StyleBoxFlat.new()

func _ready() -> void:
	layer = 2
	_style.bg_color = Color(0.04, 0.03, 0.06, 0.86)
	_style.set_content_margin_all(7.0)
	_style.content_margin_left = 12.0
	_style.content_margin_right = 12.0
	_style.border_width_bottom = 2
	_style.border_color = Color(1, 0.62, 0.3)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_constant_override("separation", 4)
	add_child(_box)
	visible = false

func say(text: String) -> void:
	if text.is_empty():
		return
	var time := clampf(text.length() * 0.09, 4.5, 11.0)
	# Powtórzony tekst tylko odświeża czas.
	if _entries and _entries[-1]["text"] == text:
		_entries[-1]["time"] = time
		return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _style)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	panel.add_child(label)
	_box.add_child(panel)
	var width := label.get_theme_font("font").get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	label.custom_minimum_size.x = minf(width + 4.0, MAX_WIDTH)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_entries.append({"panel": panel, "text": text, "time": time})
	while _entries.size() > MAX_LINES:
		_remove(0)
	# Starsze wypowiedzi są bledsze.
	for i in _entries.size():
		_entries[i]["panel"].modulate.a = 1.0 if i == _entries.size() - 1 else 0.7

func _process(delta: float) -> void:
	if not pinned:
		for i in range(_entries.size() - 1, -1, -1):
			_entries[i]["time"] -= delta
			if _entries[i]["time"] <= 0.0:
				_remove(i)
	var camera := get_viewport().get_camera_3d()
	if _entries.is_empty() or not camera:
		visible = false
		return
	var head := target.global_position + Vector3(0, height, 0)
	visible = not camera.is_position_behind(head) and (pinned or _in_sight(camera, head))
	if not visible:
		return
	_box.reset_size()
	var anchor := camera.unproject_position(head)
	var view := get_viewport().get_visible_rect().size
	var area := _box.size
	_box.position = Vector2(
		clampf(anchor.x - area.x / 2.0, MARGIN, maxf(view.x - area.x - MARGIN, MARGIN)),
		clampf(anchor.y - area.y, MARGIN, maxf(view.y - area.y - MARGIN, MARGIN)))

# Przez ściany i z daleka nie słychać.
func _in_sight(camera: Camera3D, head: Vector3) -> bool:
	if camera.global_position.distance_to(head) > RANGE:
		return false
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, head, 1)
	return camera.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _remove(index: int) -> void:
	var panel: Control = _entries[index]["panel"]
	_entries.remove_at(index)
	_box.remove_child(panel)
	panel.queue_free()
