extends CanvasLayer
# Turowa walka z grupą szczurów (po jednym naraz), jak w starych grach RPG. Szczur zdradza,
# co zrobi: przed skokiem warto się zasłonić, a skulonego przebija tylko pchnięcie.
# Pchnięcie kosztuje siły, które odzyskuje się cięciem i zasłoną. Żywcem łapie się do worka
# (minigra qte.gd). Klawisze 1-5 albo mysz.

signal killed(kind: StringName)
signal bagged(kind: StringName)
signal finished(result: StringName) # &"won", &"fled" albo &"lost"

const Sfx = preload("res://Scripts/sfx.gd")
const Speech = preload("res://Scripts/speech.gd")
const Qte = preload("res://Scripts/qte.gd")
const MAX_HP := 50
const MAX_STAMINA := 3
const STAB_COST := 2
const TURN_TIME := 0.85 # przerwa na przeczytanie, co się stało
const GUARD_CUT := 0.25 # tyle ugryzienia przechodzi przez zasłonę (skok nie przechodzi wcale)
const REPEATED_GUARD_CUT := 0.6 # zasłona drugi raz z rzędu jest słabsza
const COUNTER_BONUS := 1.5 # siła ciosu po zasłonie (taki cios zawsze trafia)
const LEAP_CHANCE := 0.3
const CURL_CHANCE := 0.2
const LEAP_POWER := 2.2
const CURL_CUT := 0.25 # tyle cięcia przebija skulonego szczura
const BAG_KEYS_MIN := 4
const BAG_KEYS_HURT := 3 # tyle klawiszy więcej przy zdrowym szczurze
const KINDS := {
	&"zwykly": {"name": "Szczur kanałowy", "hp": 18, "bite": [4, 6], "dodge": 0.0,
		"texture": "szczur", "size": 1.0, "key_time": 0.85},
	&"tlusty": {"name": "Tłusty szczur", "hp": 28, "bite": [6, 9], "dodge": 0.0,
		"texture": "szczur", "size": 1.35, "key_time": 0.75},
	&"zloty": {"name": "Złoty szczur", "hp": 22, "bite": [5, 7], "dodge": 0.2,
		"texture": "zloty", "size": 1.0, "key_time": 0.65},
}
const SPRITE_SIZE := Vector2(300, 164)
const PANEL_HEIGHT := 170.0
const ORANGE := Color(1, 0.72, 0.3)
const DANGER := Color(1, 0.35, 0.28)

var hp := MAX_HP
var bag_free := true # czy worek jest pusty (ustawia sewer.gd)
var enemies: Array[StringName] = [] # pierwszy walczy, reszta czeka
var _enemy_hp := 0
var _stamina := MAX_STAMINA
var _intent := &"bite" # bite, leap, curl
var _guard := false # zasłona w tej turze
var _counter := false # następny cios pewny i mocniejszy
var _guard_streak := 0
var _waiting := true # trwa animacja, przyciski nie działają
var _tween: Tween
var _qte # trwająca minigra (qte.gd)
var _time := 0.0

var _stage := Control.new()
var _enemy := TextureRect.new()
var _knife := Node2D.new()
var _flash := ColorRect.new()
var _enemy_box: PanelContainer
var _player_box: PanelContainer
var _enemy_name := Label.new()
var _enemy_intent := Label.new()
var _enemy_bar := ProgressBar.new()
var _enemy_hp_text := Label.new()
var _player_bar := ProgressBar.new()
var _player_hp_text := Label.new()
var _stamina_text := Label.new()
var _message := Label.new()
var _buttons: Array[Button] = []
var _enemy_home := Vector2.ZERO
var _knife_home := Vector2.ZERO

func _ready() -> void:
	layer = 8
	_build()
	hide()

func start(group: Array[StringName], start_hp: int) -> void:
	enemies = group.duplicate()
	hp = start_hp
	_stamina = MAX_STAMINA
	_guard_streak = 0
	_counter = false
	show()
	_layout()
	_refresh_player(false)
	_next_enemy()

# Przerywa walkę bez wyniku (koniec nocy).
func abort() -> void:
	if _tween:
		_tween.kill()
	if is_instance_valid(_qte):
		_qte.queue_free()
	hide()

func _process(delta: float) -> void:
	if not visible:
		return
	# Po pauzie mysz znów musi być wolna.
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Szczur i nóż lekko oddychają.
	_time += delta
	_enemy.pivot_offset = Vector2(_enemy.size.x / 2.0, _enemy.size.y)
	_enemy.scale = Vector2(1.0 + sin(_time * 5.0) * 0.015, 1.0 - sin(_time * 5.0) * 0.03)
	_knife.rotation = sin(_time * 2.0) * 0.015

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
	var index: int = event.keycode - KEY_1
	if index >= 0 and index < _buttons.size() and not _buttons[index].disabled:
		get_viewport().set_input_as_handled()
		_buttons[index].pressed.emit()

# --- Przebieg walki ---

func _next_enemy() -> void:
	var kind: Dictionary = KINDS[enemies[0]]
	_enemy_hp = kind["hp"]
	_enemy.texture = load("res://Textures/szczury/%s_0.png" % kind["texture"])
	_enemy.size = SPRITE_SIZE * kind["size"]
	_enemy.modulate = Color.WHITE
	_enemy_name.text = kind["name"] if enemies.size() == 1 \
		else "%s  (w gnieździe: %d)" % [kind["name"], enemies.size()]
	_enemy_intent.text = ""
	_enemy_bar.max_value = _enemy_hp
	_refresh_enemy(false)
	_layout()
	# Wbiega z prawej strony.
	_enemy.position = _enemy_home + Vector2(500, 0)
	create_tween().tween_property(_enemy, "position", _enemy_home, 0.45).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	Sfx.play(self, "squeak")
	_tell("%s wyskakuje z gniazda!" % kind["name"])
	_sequence([_player_turn])

# Szczur wybiera zamiar, gracz widzi go przed swoim ruchem.
func _player_turn() -> void:
	var kind: Dictionary = KINDS[enemies[0]]
	var roll := randf()
	var previous := _intent
	_intent = &"bite"
	if roll < LEAP_CHANCE:
		_intent = &"leap"
	elif roll < LEAP_CHANCE + CURL_CHANCE and previous != &"curl":
		_intent = &"curl"
	match _intent:
		&"leap":
			_enemy_intent.text = "SZYKUJE SKOK!"
			_enemy_intent.modulate = DANGER
			_tell("%s przywiera do ziemi..." % kind["name"])
			_move(_enemy, _enemy_home, Vector2(30, 14), 0.25, false)
		&"curl":
			_enemy_intent.text = "Kuli się"
			_enemy_intent.modulate = Color(0.6, 0.8, 1)
			_tell("%s zwija się w twardą kulkę." % kind["name"])
		_:
			_enemy_intent.text = "Szczerzy zęby"
			_enemy_intent.modulate = Speech.TEXT_COLOR
			_tell("Co robisz?")
	_waiting = false
	_refresh_buttons()

func _attack(stab: bool) -> void:
	if _waiting or (stab and _stamina < STAB_COST):
		return
	_lock()
	var kind: Dictionary = KINDS[enemies[0]]
	var label := "Pchnięcie" if stab else "Cięcie"
	var counter := _counter
	_counter = false
	_guard = false
	_guard_streak = 0
	_stamina = clampi(_stamina + (-STAB_COST if stab else 1), 0, MAX_STAMINA)
	_refresh_player(true)
	_move(_knife, _knife_home, Vector2(220, -110) if stab else Vector2(150, -40), 0.12, true)
	var accuracy := 0.8 if stab else 0.9
	# Kontra i pchnięcie w skulonego trafiają zawsze.
	var sure := counter or (stab and _intent == &"curl")
	if not sure and (randf() > accuracy or randf() < kind["dodge"]):
		Sfx.play(self, "wrap")
		_float_text("pudło", Color(0.75, 0.75, 0.8), _enemy_center())
		_tell("%s: pudło!" % label)
		_sequence([_rat_turn])
		return
	var damage := randi_range(10, 13) if stab else randi_range(4, 6)
	if counter:
		damage = ceili(damage * COUNTER_BONUS)
	if not stab and _intent == &"curl":
		damage = maxi(ceili(damage * CURL_CUT), 1)
		_tell("Cięcie ześlizguje się po grzbiecie: %d." % damage)
	else:
		_tell("%s trafia: %d!" % [label, damage])
	_enemy_hp = maxi(_enemy_hp - damage, 0)
	_refresh_enemy(true)
	Sfx.play(self, "plop")
	_float_text("-%d" % damage, ORANGE, _enemy_center())
	_enemy.modulate = Color(3, 3, 3)
	create_tween().tween_property(_enemy, "modulate", Color.WHITE, 0.3)
	_move(_enemy, _enemy_home, Vector2(40, -12), 0.08, true)
	_sequence([_enemy_down if _enemy_hp == 0 else _rat_turn])

func _defend() -> void:
	if _waiting:
		return
	_lock()
	_guard = true
	_guard_streak += 1
	_stamina = clampi(_stamina + 2, 0, MAX_STAMINA)
	_refresh_player(true)
	_move(_knife, _knife_home, Vector2(80, -90), 0.15, true)
	_tell("Zasłaniasz się i łapiesz oddech.")
	_sequence([_rat_turn])

func _bag() -> void:
	if _waiting or not bag_free:
		return
	_lock()
	_guard = false
	_counter = false
	_guard_streak = 0
	var kind: Dictionary = KINDS[enemies[0]]
	var health := float(_enemy_hp) / float(kind["hp"])
	_tell("Otwierasz worek...")
	_qte = Qte.new()
	add_child(_qte)
	_qte.done.connect(_on_bag_done)
	_qte.start("Zagoń go do worka!", BAG_KEYS_MIN + roundi(BAG_KEYS_HURT * health), kind["key_time"])

func _on_bag_done(success: bool) -> void:
	if not success:
		_tell("Wymyka się z worka!")
		_sequence([_rat_turn])
		return
	var kind: StringName = enemies.pop_front()
	_tell("%s siedzi w worku. Żywy!" % KINDS[kind]["name"])
	Sfx.play(self, "squeak")
	_enemy.modulate.a = 0.0
	bag_free = false
	bagged.emit(kind)
	_sequence([_finish.bind(&"won") if enemies.is_empty() else _next_enemy])

func _flee() -> void:
	if _waiting:
		return
	_lock()
	_tell("Uciekasz!")
	_sequence([_finish.bind(&"fled")])

func _rat_turn() -> void:
	var kind: Dictionary = KINDS[enemies[0]]
	var guarded := _guard
	_guard = false
	if guarded:
		_counter = true
	if _intent == &"curl":
		_tell("%s czeka skulony." % kind["name"])
		_sequence([_player_turn])
		return
	var damage := randi_range(kind["bite"][0], kind["bite"][1])
	var leap := _intent == &"leap"
	if leap:
		damage = roundi(damage * LEAP_POWER)
	if guarded:
		var cut := GUARD_CUT if _guard_streak < 2 else REPEATED_GUARD_CUT
		damage = 0 if leap and _guard_streak < 2 else ceili(damage * cut)
	_move(_enemy, _enemy_home, Vector2(-260, 120) if leap else Vector2(-130, 60), 0.16, true)
	if damage == 0:
		Sfx.play(self, "wrap")
		_tell("Skok odbija się od zasłony! Teraz kontra.")
		_float_text("blok", Color(0.6, 0.85, 1), _knife_home + Vector2(220, 20))
		_sequence([_player_turn])
		return
	hp = maxi(hp - damage, 0)
	_refresh_player(true)
	Sfx.play(self, "angry", -6.0)
	_hurt(damage)
	_tell("%s %s: -%d" % [kind["name"], "rzuca ci się do gardła" if leap else "gryzie", damage])
	_sequence([_finish.bind(&"lost") if hp == 0 else _player_turn])

func _enemy_down() -> void:
	var kind: StringName = enemies.pop_front()
	_tell("%s pada! Truchło ląduje w torbie." % KINDS[kind]["name"])
	_enemy_intent.text = ""
	var fall := create_tween().set_parallel()
	fall.tween_property(_enemy, "position", _enemy_home + Vector2(0, 70), 0.4)
	fall.tween_property(_enemy, "modulate", Color(0.6, 0.1, 0.1, 0.0), 0.6)
	Sfx.play(self, "trash")
	killed.emit(kind)
	_sequence([_finish.bind(&"won") if enemies.is_empty() else _next_enemy])

func _finish(result: StringName) -> void:
	hide()
	finished.emit(result)

func _lock() -> void:
	_waiting = true
	_refresh_buttons()

# Po chwili wykonuje następne kroki (tween należy do tego węzła, więc pauza go zatrzymuje).
func _sequence(steps: Array) -> void:
	_lock()
	_tween = create_tween()
	_tween.tween_interval(TURN_TIME)
	for step in steps:
		_tween.tween_callback(step)

# --- Efekty ---

func _tell(text: String) -> void:
	_message.text = text

# Ruch z miejsca "home" o "offset"; z powrotem albo na stałe (do następnego ruchu).
func _move(node: Node, home: Vector2, offset: Vector2, time: float, back: bool) -> void:
	var tween := create_tween()
	tween.tween_property(node, "position", home + offset, time)
	if back:
		tween.tween_property(node, "position", home, time * 1.8)

# Czerwony błysk i wstrząs ekranu.
func _hurt(damage: int) -> void:
	_flash.color.a = 0.45
	create_tween().tween_property(_flash, "color:a", 0.0, 0.45)
	var tween := create_tween()
	for offset in [Vector2(18, -8), Vector2(-14, 10), Vector2(9, -5), Vector2(-5, 2), Vector2.ZERO]:
		tween.tween_property(_stage, "position", offset, 0.05)
	_float_text("-%d" % damage, DANGER, _player_box.position + Vector2(60, -30))

func _float_text(text: String, color: Color, at: Vector2) -> void:
	var label := Label.new()
	_style_text(label, 40)
	label.text = text
	label.modulate = color
	label.position = at
	_stage.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", at.y - 80.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)

func _enemy_center() -> Vector2:
	return _enemy_home + Vector2(_enemy.size.x / 2.0 - 30.0, 0.0)

func _refresh_enemy(animate: bool) -> void:
	_set_bar(_enemy_bar, _enemy_hp, animate)
	_enemy_hp_text.text = "Zdrowie: %d / %d" % [_enemy_hp, int(_enemy_bar.max_value)]

func _refresh_player(animate: bool) -> void:
	_set_bar(_player_bar, hp, animate)
	_player_hp_text.text = "Zdrowie: %d / %d" % [hp, MAX_HP]
	_stamina_text.text = "Siły: %s%s" % ["■ ".repeat(_stamina), "□ ".repeat(MAX_STAMINA - _stamina)]

# Pasek zmienia kolor: zielony, żółty, czerwony.
func _set_bar(bar: ProgressBar, value: int, animate: bool) -> void:
	var ratio := value / bar.max_value
	var fill: StyleBoxFlat = bar.get_theme_stylebox("fill")
	fill.bg_color = Color(0.35, 0.8, 0.35) if ratio > 0.5 else \
		(Color(0.95, 0.75, 0.2) if ratio > 0.2 else Color(0.9, 0.25, 0.2))
	if animate:
		create_tween().tween_property(bar, "value", float(value), 0.35)
	else:
		bar.value = value

func _refresh_buttons() -> void:
	for button in _buttons:
		button.disabled = _waiting
	if _stamina < STAB_COST:
		_buttons[1].disabled = true
	if not bag_free:
		_buttons[3].disabled = true

# --- Wygląd ---

func _build() -> void:
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.draw.connect(_draw_background)
	add_child(_stage)

	_enemy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_enemy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_enemy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage.add_child(_enemy)
	_draw_knife()
	_stage.add_child(_knife)

	_enemy_box = _info_box()
	var enemy_column := _enemy_box.get_child(0)
	_style_text(_enemy_name, 22)
	enemy_column.add_child(_enemy_name)
	_bar(enemy_column, _enemy_bar)
	_style_text(_enemy_hp_text, 16)
	enemy_column.add_child(_enemy_hp_text)
	_style_text(_enemy_intent, 22)
	enemy_column.add_child(_enemy_intent)

	_player_box = _info_box()
	var player_column := _player_box.get_child(0)
	var you := Label.new()
	_style_text(you, 22)
	you.text = "Ty i twój nóż"
	player_column.add_child(you)
	_player_bar.max_value = MAX_HP
	_bar(player_column, _player_bar)
	_style_text(_player_hp_text, 16)
	player_column.add_child(_player_hp_text)
	_style_text(_stamina_text, 18)
	player_column.add_child(_stamina_text)

	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", _frame(Color(0.07, 0.05, 0.1, 0.97), ORANGE))
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -PANEL_HEIGHT
	_stage.add_child(bottom)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	bottom.add_child(column)
	_style_text(_message, 24)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_message)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	_button(grid, "Cięcie  (+1 siła)", _attack.bind(false))
	_button(grid, "Pchnięcie  (-2 siły)", _attack.bind(true))
	_button(grid, "Zasłona  (+2 siły)", _defend)
	_button(grid, "Worek  (żywcem)", _bag)
	_button(grid, "Ucieczka", _flee)

	_flash.color = Color(0.8, 0.05, 0.02, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	# Dopiero teraz: układanie potrzebuje wszystkich elementów.
	_stage.resized.connect(_layout)

# Rozstawienie zależy od rozmiaru okna.
func _layout() -> void:
	var area := _stage.size
	_enemy_home = Vector2(area.x * 0.7 - _enemy.size.x / 2.0, area.y * 0.44 - _enemy.size.y * 0.85)
	_enemy.position = _enemy_home
	_knife_home = Vector2(area.x * 0.04, area.y - PANEL_HEIGHT - 190.0)
	_knife.position = _knife_home
	_enemy_box.position = Vector2(28, 24)
	_player_box.position = Vector2(area.x - 388.0, area.y - PANEL_HEIGHT - 150.0)
	_stage.queue_redraw()

# Ceglany tunel, ściek i dwie "areny" pod walczącymi.
func _draw_background() -> void:
	var area := _stage.size
	var horizon := area.y * 0.34
	# tło z zapasem, żeby przy wstrząsie nie było widać krawędzi
	_stage.draw_rect(Rect2(-30, -30, area.x + 60, area.y + 60), Color(0.05, 0.07, 0.06))
	var row := 0
	var y := 0.0
	while y < horizon:
		var x := -80.0 + (row % 2) * 40.0
		var column := 0
		while x < area.x:
			var shade := 0.8 + float((row * 7 + column * 13) % 5) * 0.08
			var fade := 0.55 + 0.45 * y / horizon
			_stage.draw_rect(Rect2(x, y, 76, 28), Color(0.2, 0.24, 0.19) * Color(shade * fade, shade * fade, shade * fade))
			x += 80.0
			column += 1
		y += 32.0
		row += 1
	# lampa i jej poświata
	var lamp := Vector2(area.x * 0.45, 26)
	for i in 5:
		_stage.draw_circle(lamp, 130.0 - i * 22.0, Color(0.75, 0.9, 0.45, 0.035))
	_stage.draw_circle(lamp, 9.0, Color(0.9, 1, 0.7))
	# rura i zacieki
	_stage.draw_rect(Rect2(0, horizon - 46, area.x, 16), Color(0.3, 0.17, 0.1))
	_stage.draw_rect(Rect2(0, horizon - 46, area.x, 4), Color(0.48, 0.3, 0.18))
	for i in 7:
		var drip := area.x * (0.08 + i * 0.14)
		_stage.draw_rect(Rect2(drip, horizon - 30, 4, 18.0 + (i * 11) % 24), Color(0.25, 0.45, 0.2, 0.6))
	# podłoga i ściek
	_stage.draw_rect(Rect2(0, horizon, area.x, area.y - horizon), Color(0.13, 0.14, 0.12))
	_stage.draw_colored_polygon(PackedVector2Array([
		Vector2(area.x * 0.44, horizon), Vector2(area.x * 0.5, horizon),
		Vector2(area.x * 0.4, area.y), Vector2(area.x * 0.18, area.y)]), Color(0.08, 0.2, 0.11))
	for i in 6:
		var depth := horizon + 14.0 + i * i * 9.0
		_stage.draw_rect(Rect2(area.x * (0.45 - i * 0.032), depth, 34.0 + i * 8.0, 3), Color(0.3, 0.55, 0.3, 0.5))
	_platform(Vector2(area.x * 0.7, area.y * 0.45), 220.0)
	_platform(Vector2(area.x * 0.22, area.y - PANEL_HEIGHT - 12.0), 300.0)

func _platform(center: Vector2, radius: float) -> void:
	_stage.draw_set_transform(center, 0.0, Vector2(1.0, 0.24))
	_stage.draw_circle(Vector2(0, 26), radius, Color(0.04, 0.04, 0.04, 0.7))
	_stage.draw_circle(Vector2.ZERO, radius, Color(0.27, 0.26, 0.21))
	_stage.draw_circle(Vector2(0, -8), radius * 0.82, Color(0.33, 0.32, 0.25))
	_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _info_box() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _frame(Color(0.08, 0.06, 0.11, 0.92), Speech.TEXT_COLOR))
	panel.custom_minimum_size.x = 360
	var column := VBoxContainer.new()
	panel.add_child(column)
	_stage.add_child(panel)
	return panel

func _frame(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	return style

func _bar(parent: Node, bar: ProgressBar) -> void:
	var fill := StyleBoxFlat.new()
	var empty := StyleBoxFlat.new()
	empty.bg_color = Color(0.02, 0.02, 0.02)
	empty.set_border_width_all(2)
	empty.border_color = Color(0.4, 0.38, 0.35)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", empty)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(330, 18)
	parent.add_child(bar)

func _style_text(label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Speech.TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", Speech.OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", Speech.OUTLINE)

func _button(parent: Node, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = "%d. %s" % [_buttons.size() + 1, text]
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Speech.TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", ORANGE)
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.43, 0.45))
	button.add_theme_stylebox_override("normal", _frame(Color(0.17, 0.13, 0.2), Color(0.5, 0.45, 0.5)))
	button.add_theme_stylebox_override("hover", _frame(Color(0.26, 0.18, 0.22), ORANGE))
	button.add_theme_stylebox_override("pressed", _frame(Color(0.35, 0.24, 0.2), ORANGE))
	button.add_theme_stylebox_override("disabled", _frame(Color(0.1, 0.09, 0.12), Color(0.25, 0.23, 0.26)))
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.get_theme_stylebox(state).set_content_margin_all(5)
	button.pressed.connect(action)
	parent.add_child(button)
	_buttons.append(button)

# Ręka z nożem z kilku wielokątów, ostrzem w stronę szczura.
func _draw_knife() -> void:
	_shape([-70, 250, 20, 130, 105, 175, 40, 270], Color(0.2, 0.22, 0.3)) # rękaw
	_shape([30, 135, 75, 105, 135, 120, 140, 160, 100, 185, 55, 170], Color(0.82, 0.6, 0.46)) # dłoń
	_shape([95, 75, 135, 55, 175, 105, 140, 130], Color(0.28, 0.16, 0.09)) # rękojeść
	for i in 3:
		var x := 92 + i * 17
		_shape([x, 112 + i * 4, x + 14, 104 + i * 4, x + 26, 134 + i * 4, x + 10, 142 + i * 4],
			Color(0.9, 0.68, 0.52)) # palce
	_shape([115, 40, 135, 30, 195, 108, 172, 118], Color(0.5, 0.45, 0.25)) # jelec
	_shape([128, 40, 330, -70, 372, -62, 290, 20, 175, 92], Color(0.68, 0.72, 0.76)) # ostrze
	_shape([150, 45, 330, -62, 355, -60, 170, 62], Color(0.92, 0.95, 0.98)) # błysk

# Punkty jako płaska lista x, y; z ciemnym obrysem.
func _shape(flat: Array, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(0, flat.size(), 2):
		points.append(Vector2(flat[i], flat[i + 1]))
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	_knife.add_child(polygon)
	var line := Line2D.new()
	line.points = points
	line.closed = true
	line.width = 4.0
	line.default_color = Speech.OUTLINE_COLOR
	_knife.add_child(line)
