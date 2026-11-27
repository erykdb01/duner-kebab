extends CanvasLayer
# Turowa walka z grupą szczurów (po jednym naraz), jak w starych grach RPG.
# Klawisze 1-4 albo mysz. Pauza gry zatrzymuje też walkę.

signal killed(kind: StringName)
signal finished(result: StringName) # &"won", &"fled" albo &"lost"

const Sfx = preload("res://Scripts/sfx.gd")
const Speech = preload("res://Scripts/speech.gd")
const MAX_HP := 50
const TURN_TIME := 0.7 # przerwa na przeczytanie, co się stało
const GUARD_CUT := 0.25 # tyle obrażeń przechodzi przez zasłonę
const COUNTER_BONUS := 1.5 # siła ciosu po zasłonie (taki cios zawsze trafia)
const SQUEAK_CHANCE := 0.15
const HARD_BITE_CHANCE := 0.15
const HARD_BITE_BONUS := 3
# Ataki: [nazwa, obrażenia od, do, szansa trafienia]
const ATTACKS := {
	&"slash": ["Cięcie", 4, 6, 0.95],
	&"stab": ["Pchnięcie", 8, 11, 0.65],
}
const KINDS := {
	&"zwykly": {"name": "Szczur kanałowy", "hp": 10, "bite": [2, 4], "dodge": 0.0,
		"texture": "szczur", "size": 1.0},
	&"tlusty": {"name": "Tłusty szczur", "hp": 17, "bite": [4, 6], "dodge": 0.0,
		"texture": "szczur", "size": 1.35},
	&"zloty": {"name": "Złoty szczur", "hp": 14, "bite": [3, 5], "dodge": 0.25,
		"texture": "zloty", "size": 1.0},
}
const SPRITE_SIZE := Vector2(288, 156)

var hp := MAX_HP
var enemies: Array[StringName] = [] # pierwszy walczy, reszta czeka
var _enemy_hp := 0
var _guard := false
var _waiting := true # trwa animacja, przyciski nie działają
var _tween: Tween

var _enemy_name := Label.new()
var _enemy_bar := ProgressBar.new()
var _enemy := TextureRect.new()
var _player_name := Label.new()
var _player_bar := ProgressBar.new()
var _knife := Control.new()
var _message := Label.new()
var _buttons := HBoxContainer.new()

func _ready() -> void:
	layer = 8
	_build()
	hide()

func start(group: Array[StringName], start_hp: int) -> void:
	enemies = group.duplicate()
	hp = start_hp
	_guard = false
	_refresh_player()
	show()
	_next_enemy()

# Przerywa walkę bez wyniku (koniec nocy).
func abort() -> void:
	if _tween:
		_tween.kill()
	hide()

func _process(_delta: float) -> void:
	# Po pauzie mysz znów musi być wolna.
	if visible and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
	var index: int = event.keycode - KEY_1
	if index >= 0 and index < _buttons.get_child_count():
		get_viewport().set_input_as_handled()
		_buttons.get_child(index).pressed.emit()

# --- Przebieg walki ---

func _next_enemy() -> void:
	var kind: Dictionary = KINDS[enemies[0]]
	_enemy_hp = kind["hp"]
	_enemy.texture = load("res://Textures/szczury/%s_0.png" % kind["texture"])
	_enemy.custom_minimum_size = SPRITE_SIZE * kind["size"]
	_enemy.size = _enemy.custom_minimum_size
	_enemy.position = Vector2.ZERO
	_enemy.modulate = Color.WHITE
	_enemy_name.text = kind["name"] if enemies.size() == 1 \
		else "%s (zostało: %d)" % [kind["name"], enemies.size()]
	_enemy_bar.max_value = _enemy_hp
	_enemy_bar.value = _enemy_hp
	Sfx.play(self, "squeak")
	_tell("%s szczerzy zęby!" % kind["name"])
	_sequence([_ready_for_turn])

func _ready_for_turn() -> void:
	_waiting = false
	_buttons.modulate.a = 1.0

func _attack(id: StringName) -> void:
	if _waiting:
		return
	_lock()
	var attack: Array = ATTACKS[id]
	var kind: Dictionary = KINDS[enemies[0]]
	var sure := _guard
	_guard = false
	if not sure and (randf() > attack[3] or randf() < kind["dodge"]):
		Sfx.play(self, "wrap")
		_tell("%s: pudło!" % attack[0])
		_sequence([_rat_turn])
		return
	var damage := randi_range(attack[1], attack[2])
	if sure:
		damage = ceili(damage * COUNTER_BONUS)
	_enemy_hp = maxi(_enemy_hp - damage, 0)
	_enemy_bar.value = _enemy_hp
	Sfx.play(self, "plop")
	_shake(_enemy)
	_tell("%s: %d obrażeń!" % [attack[0], damage])
	_sequence([_enemy_down if _enemy_hp == 0 else _rat_turn])

func _defend() -> void:
	if _waiting:
		return
	_lock()
	_guard = true
	_tell("Zasłaniasz się. Następny cios będzie pewny i mocniejszy.")
	_sequence([_rat_turn])

func _flee() -> void:
	if _waiting:
		return
	_lock()
	_tell("Uciekasz!")
	_sequence([_finish.bind(&"fled")])

func _rat_turn() -> void:
	var kind: Dictionary = KINDS[enemies[0]]
	if randf() < SQUEAK_CHANCE:
		Sfx.play(self, "squeak")
		_tell("%s tylko piszczy." % kind["name"])
		_sequence([_ready_for_turn])
		return
	var damage := randi_range(kind["bite"][0], kind["bite"][1])
	var text := "%s gryzie"
	if randf() < HARD_BITE_CHANCE:
		damage += HARD_BITE_BONUS
		text = "%s wgryza się z całej siły"
	if _guard:
		damage = ceili(damage * GUARD_CUT)
	hp = maxi(hp - damage, 0)
	_refresh_player()
	Sfx.play(self, "angry", -6.0)
	_shake(_knife)
	_tell((text + ": -%d") % [kind["name"], damage])
	_sequence([_finish.bind(&"lost") if hp == 0 else _ready_for_turn])

func _enemy_down() -> void:
	var kind: StringName = enemies.pop_front()
	_tell("%s pada! Truchło ląduje w torbie." % KINDS[kind]["name"])
	_enemy.modulate = Color(0.5, 0.2, 0.2, 0.5)
	Sfx.play(self, "trash")
	killed.emit(kind)
	_sequence([_finish.bind(&"won") if enemies.is_empty() else _next_enemy])

func _finish(result: StringName) -> void:
	hide()
	finished.emit(result)

func _lock() -> void:
	_waiting = true
	_buttons.modulate.a = 0.45

# Po chwili wykonuje następne kroki (tween należy do tego węzła, więc pauza go zatrzymuje).
func _sequence(steps: Array) -> void:
	_lock()
	_tween = create_tween()
	_tween.tween_interval(TURN_TIME)
	for step in steps:
		_tween.tween_callback(step)

func _tell(text: String) -> void:
	_message.text = text

func _shake(node: Control) -> void:
	var tween := create_tween()
	for offset in [14.0, -12.0, 8.0, -5.0, 0.0]:
		tween.tween_property(node, "position:x", offset, 0.05).as_relative().from_current()

func _refresh_player() -> void:
	_player_name.text = "Ty: %d / %d" % [hp, MAX_HP]
	_player_bar.value = hp

# --- Wygląd ---

func _build() -> void:
	var back := ColorRect.new()
	back.color = Color(0.07, 0.09, 0.07, 0.96)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)

	# góra: dane przeciwnika po lewej, szczur po prawej
	var top := _row(column)
	_info(top, _enemy_name, _enemy_bar, Color(0.85, 0.25, 0.2))
	_spacer(top)
	_enemy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_enemy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_enemy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_slot(top, _enemy, SPRITE_SIZE * 1.4)

	# dół: nóż po lewej, twoje zdrowie po prawej
	var bottom := _row(column)
	_slot(bottom, _knife, Vector2(300, 150))
	_draw_knife()
	_spacer(bottom)
	_player_bar.max_value = MAX_HP
	_info(bottom, _player_name, _player_bar, Color(0.35, 0.8, 0.35))

	_text(_message, 22)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.custom_minimum_size.y = 56
	column.add_child(_message)
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 16)
	column.add_child(_buttons)
	_button("Cięcie (pewne)", _attack.bind(&"slash"))
	_button("Pchnięcie (mocne, ryzykowne)", _attack.bind(&"stab"))
	_button("Zasłona", _defend)
	_button("Ucieczka", _flee)

func _row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	return row

func _spacer(parent: Control) -> void:
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(space)

# Miejsce, w którym obrazek może się trząść (kontener nie ustawia go sam).
func _slot(parent: Control, node: Control, size: Vector2) -> void:
	var slot := Control.new()
	slot.custom_minimum_size = size
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(slot)
	slot.add_child(node)

func _info(parent: Control, title: Label, bar: ProgressBar, color: Color) -> void:
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(box)
	_text(title, 24)
	box.add_child(title)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var empty := StyleBoxFlat.new()
	empty.bg_color = Color(0.02, 0.02, 0.02)
	empty.set_border_width_all(2)
	empty.border_color = Speech.TEXT_COLOR
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", empty)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(320, 20)
	box.add_child(bar)

func _text(label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Speech.TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", Speech.OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", Speech.OUTLINE)

func _button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = "%d. %s" % [_buttons.get_child_count() + 1, text]
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(action)
	_buttons.add_child(button)

# Nóż z kilku wielokątów, trzymany ostrzem w stronę szczura.
func _draw_knife() -> void:
	var parts := [
		[Color(0.75, 0.78, 0.8), [Vector2(100, 85), Vector2(285, 5), Vector2(235, 70), Vector2(120, 115)]],
		[Color(0.3, 0.18, 0.1), [Vector2(20, 120), Vector2(100, 85), Vector2(120, 115), Vector2(40, 150)]],
		[Color(0.85, 0.65, 0.5), [Vector2(0, 125), Vector2(55, 100), Vector2(80, 135), Vector2(25, 165)]],
	]
	for part in parts:
		var polygon := Polygon2D.new()
		polygon.color = part[0]
		polygon.polygon = PackedVector2Array(part[1])
		_knife.add_child(polygon)
