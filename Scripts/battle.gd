extends CanvasLayer
# Turowa walka z grupą szczurów (po jednym naraz), jak w starych grach RPG. Szczur zdradza,
# co zrobi: przed skokiem warto się zasłonić, a skulonego przebija tylko pchnięcie.
# Pchnięcie kosztuje siły, które odzyskuje się cięciem i zasłoną. Żywcem łapie się do worka
# (minigra qte.gd). Klawisze 1-5 albo mysz.
# Tłem jest sam kanał (3D) i nóż trzymany przed kamerą; interfejs przechodzi przez ten sam
# filtr pikseli co świat.

signal killed(kind: StringName)
signal bagged(kind: StringName)
signal finished(result: StringName) # &"won", &"fled" albo &"lost"

const Sfx = preload("res://Scripts/sfx.gd")
const Qte = preload("res://Scripts/qte.gd")
const Ui = preload("res://Scripts/pixel_ui.gd")
const PixelShader = preload("res://Materials/pixel.gdshader")
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
# "key_time" to czas na klawisz przy łapaniu do worka; 0 = nie mieści się w worku.
const KINDS := {
	&"zwykly": {"name": "Szczur kanałowy", "hp": 18, "bite": [4, 6], "dodge": 0.0,
		"texture": "szczur", "size": 1.0, "tint": Color.WHITE, "key_time": 0.85},
	&"tlusty": {"name": "Tłusty szczur", "hp": 28, "bite": [6, 9], "dodge": 0.0,
		"texture": "szczur", "size": 1.35, "tint": Color.WHITE, "key_time": 0.75},
	&"wielki": {"name": "Wielki szczur", "hp": 46, "bite": [6, 9], "dodge": 0.0,
		"texture": "szczur", "size": 1.8, "tint": Color(0.75, 0.55, 0.5), "key_time": 0.0},
	&"zloty": {"name": "Złoty szczur", "hp": 22, "bite": [5, 7], "dodge": 0.2,
		"texture": "zloty", "size": 1.0, "tint": Color.WHITE, "key_time": 0.65},
	&"pimpek": {"name": "Pimpek (czerwona kokardka)", "hp": 20, "bite": [3, 5], "dodge": 0.0,
		"texture": "pimpek", "size": 1.0, "tint": Color.WHITE, "key_time": 0.8},
}
const SPRITE_SIZE := Vector2(288, 156)
const SPRITE_TINT := Color(0.82, 0.82, 0.74) # szczur w półmroku kanału
const PANEL_HEIGHT := 138.0
const FILTER_PIXELS := 2.0 # wielkość piksela interfejsu walki

var hp := MAX_HP
var bag_free := true # czy worek jest pusty (ustawia sewer.gd)
var knife: Node3D # nóż przed kamerą (ustawia sewer.gd)
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
var _foot := Vector3.ZERO # punkt w kanale, na którym stoi walczący szczur

var _stage := Control.new()
var _shadow := TextureRect.new()
var _enemy := TextureRect.new()
var _flash := ColorRect.new()
var _enemy_box: PanelContainer
var _player_box: PanelContainer
var _enemy_name := Label.new()
var _enemy_intent := Label.new()
var _enemy_bar := ProgressBar.new()
var _enemy_hp_text := Label.new()
var _player_bar := ProgressBar.new()
var _player_hp_text := Label.new()
var _stamina_blocks: Array[ColorRect] = []
var _message := Label.new()
var _buttons: Array[Button] = []
var _enemy_home := Vector2.ZERO
var _knife_home := Vector3.ZERO

func _ready() -> void:
	layer = 8
	_build()
	hide()

# "foot" to miejsce w świecie, gdzie ma stać szczur; nóż powinien być już uniesiony.
func start(group: Array[StringName], start_hp: int, foot: Vector3) -> void:
	enemies = group.duplicate()
	hp = start_hp
	_foot = foot
	_knife_home = knife.position
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
	# Szczur lekko oddycha.
	_time += delta
	_enemy.pivot_offset = Vector2(_enemy.size.x / 2.0, _enemy.size.y)
	_enemy.scale = Vector2(1.0 + sin(_time * 5.0) * 0.015, 1.0 - sin(_time * 5.0) * 0.03)

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
	_enemy.modulate = _tint()
	_enemy_name.text = kind["name"] if enemies.size() == 1 \
		else "%s (w gnieździe: %d)" % [kind["name"], enemies.size()]
	_enemy_intent.text = " "
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
			_enemy_intent.modulate = Ui.DANGER
			_tell("%s przywiera do ziemi..." % kind["name"])
			_move(_enemy, _enemy_home, Vector2(0, 14), 0.25, false)
		&"curl":
			_enemy_intent.text = "Kuli się"
			_enemy_intent.modulate = Color(0.55, 0.72, 0.9)
			_tell("%s zwija się w twardą kulkę." % kind["name"])
		_:
			_enemy_intent.text = "Szczerzy zęby"
			_enemy_intent.modulate = Color.WHITE
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
	_swing(Vector3(-0.2, 0.06, -0.22) if stab else Vector3(-0.34, 0.05, -0.05),
		0.0 if stab else 0.7)
	var accuracy := 0.8 if stab else 0.9
	# Kontra i pchnięcie w skulonego trafiają zawsze.
	var sure := counter or (stab and _intent == &"curl")
	if not sure and (randf() > accuracy or randf() < kind["dodge"]):
		Sfx.play(self, "wrap")
		_float_text("pudło", Ui.DIM, _enemy_center())
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
	_float_text("-%d" % damage, Ui.ACCENT, _enemy_center())
	_enemy.modulate = Color(2.5, 2.5, 2.5)
	create_tween().tween_property(_enemy, "modulate", _tint(), 0.3)
	_move(_enemy, _enemy_home, Vector2(22, -14), 0.08, true)
	_sequence([_enemy_down if _enemy_hp == 0 else _rat_turn])

func _defend() -> void:
	if _waiting:
		return
	_lock()
	_guard = true
	_guard_streak += 1
	_stamina = clampi(_stamina + 2, 0, MAX_STAMINA)
	_refresh_player(true)
	_swing(Vector3(-0.2, 0.08, 0.02), 1.2)
	_tell("Zasłaniasz się i łapiesz oddech.")
	_sequence([_rat_turn])

# Czy walczący teraz szczur zmieści się do (wolnego) worka.
func _can_bag() -> bool:
	return bag_free and not enemies.is_empty() and KINDS[enemies[0]]["key_time"] > 0.0

func _tint() -> Color:
	return SPRITE_TINT * KINDS[enemies[0]]["tint"]

func _bag() -> void:
	if _waiting or not _can_bag():
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
	# Rzuca się w stronę kamery, czyli w dół ekranu.
	_move(_enemy, _enemy_home, Vector2(0, 150) if leap else Vector2(0, 70), 0.16, true)
	if damage == 0:
		Sfx.play(self, "wrap")
		_tell("Skok odbija się od zasłony! Teraz kontra.")
		_float_text("blok", Color(0.55, 0.72, 0.9), _enemy_center() + Vector2(0, 90))
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
	_enemy_intent.text = " "
	var fall := create_tween().set_parallel()
	fall.tween_property(_enemy, "position", _enemy_home + Vector2(0, 30), 0.4)
	fall.tween_property(_enemy, "modulate", Color(0.5, 0.05, 0.05, 0.0), 0.6)
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
func _move(node: Control, home: Vector2, offset: Vector2, time: float, back: bool) -> void:
	var tween := create_tween()
	tween.tween_property(node, "position", home + offset, time)
	if back:
		tween.tween_property(node, "position", home, time * 1.8)

# Zamach nożem: przesunięcie i obrót, potem powrót.
func _swing(offset: Vector3, roll: float) -> void:
	var rest := knife.rotation.z
	var tween := create_tween()
	tween.tween_property(knife, "position", _knife_home + offset, 0.12)
	tween.parallel().tween_property(knife, "rotation:z", rest + roll, 0.12)
	tween.tween_property(knife, "position", _knife_home, 0.28)
	tween.parallel().tween_property(knife, "rotation:z", rest, 0.28)

# Czerwony błysk i wstrząs ekranu.
func _hurt(damage: int) -> void:
	_flash.color.a = 0.4
	create_tween().tween_property(_flash, "color:a", 0.0, 0.45)
	var tween := create_tween()
	for offset in [Vector2(16, -8), Vector2(-12, 10), Vector2(8, -4), Vector2(-4, 2), Vector2.ZERO]:
		tween.tween_property(_stage, "position", offset, 0.05)
	_float_text("-%d" % damage, Ui.DANGER, _player_box.position + Vector2(90, -50))

func _float_text(text: String, color: Color, at: Vector2) -> void:
	var label := Ui.label(34, text)
	label.modulate = color
	label.position = at
	_stage.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", at.y - 70.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)

func _enemy_center() -> Vector2:
	return _enemy_home + Vector2(_enemy.size.x / 2.0 - 30.0, 0.0)

func _refresh_enemy(animate: bool) -> void:
	_set_bar(_enemy_bar, _enemy_hp, animate)
	_enemy_hp_text.text = "Zdrowie %d/%d" % [_enemy_hp, int(_enemy_bar.max_value)]

func _refresh_player(animate: bool) -> void:
	_set_bar(_player_bar, hp, animate)
	_player_hp_text.text = "Zdrowie %d/%d" % [hp, MAX_HP]
	for i in _stamina_blocks.size():
		_stamina_blocks[i].color = Ui.ACCENT if i < _stamina else Ui.EMPTY

# Pasek zmienia kolor: zielony, żółty, czerwony.
func _set_bar(bar: ProgressBar, value: int, animate: bool) -> void:
	var ratio := value / bar.max_value
	var fill: StyleBoxFlat = bar.get_theme_stylebox("fill")
	fill.bg_color = Ui.GOOD if ratio > 0.5 else (Ui.WARN if ratio > 0.2 else Ui.BAD)
	if animate:
		create_tween().tween_property(bar, "value", float(value), 0.35)
	else:
		bar.value = value

func _refresh_buttons() -> void:
	for button in _buttons:
		button.disabled = _waiting
	if _stamina < STAB_COST:
		_buttons[1].disabled = true
	if not _can_bag():
		_buttons[3].disabled = true

# --- Wygląd ---

func _build() -> void:
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.theme = Ui.theme()
	add_child(_stage)
	# lekkie przyciemnienie kanału, żeby szczur i napisy się odcinały
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.01, 0.3)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(shade)

	_shadow.texture = load("res://Textures/swiat/cien.png")
	_sharp(_shadow)
	_shadow.stretch_mode = TextureRect.STRETCH_SCALE
	_stage.add_child(_shadow)
	_sharp(_enemy)
	_enemy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage.add_child(_enemy)

	_enemy_box = _info_box()
	var enemy_column := _enemy_box.get_child(0)
	_add_label(enemy_column, _enemy_name, 18)
	Ui.bar(enemy_column, _enemy_bar)
	_add_label(enemy_column, _enemy_hp_text, 14)
	_add_label(enemy_column, _enemy_intent, 20)

	_player_box = _info_box()
	var player_column := _player_box.get_child(0)
	_add_label(player_column, Ui.label(18, "Ty i twój nóż"), 18)
	_player_bar.max_value = MAX_HP
	Ui.bar(player_column, _player_bar)
	_add_label(player_column, _player_hp_text, 14)
	var stamina := HBoxContainer.new()
	stamina.add_theme_constant_override("separation", 6)
	player_column.add_child(stamina)
	stamina.add_child(Ui.label(16, "Siły"))
	for i in MAX_STAMINA:
		var block := ColorRect.new()
		block.custom_minimum_size = Vector2(22, 14)
		block.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		stamina.add_child(block)
		_stamina_blocks.append(block)

	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", Ui.frame())
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -PANEL_HEIGHT
	_stage.add_child(bottom)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	bottom.add_child(column)
	_add_label(column, _message, 20)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)
	_button(grid, "Cięcie (+1 siła)", _attack.bind(false))
	_button(grid, "Pchnięcie (-2 siły)", _attack.bind(true))
	_button(grid, "Zasłona (+2 siły)", _defend)
	_button(grid, "Worek (żywcem)", _bag)
	_button(grid, "Ucieczka", _flee)

	_flash.color = Color(0.6, 0.02, 0.0, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_add_filter()
	# Dopiero teraz: układanie potrzebuje wszystkich elementów.
	_stage.resized.connect(_layout)

# Ten sam filtr pikseli co na świecie, nałożony także na interfejs walki.
func _add_filter() -> void:
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(copy)
	var filter := ColorRect.new()
	var material := ShaderMaterial.new()
	material.shader = PixelShader
	material.set_shader_parameter("pixel_size", FILTER_PIXELS)
	material.set_shader_parameter("levels", 32.0)
	filter.material = material
	filter.set_anchors_preset(Control.PRESET_FULL_RECT)
	filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(filter)

# Szczur stoi tam, gdzie w kanale leży jego gniazdo.
func _layout() -> void:
	var area := _stage.size
	var feet := Vector2(area.x * 0.5, area.y * 0.66)
	var camera := get_viewport().get_camera_3d()
	if camera and not camera.is_position_behind(_foot):
		feet = camera.unproject_position(_foot)
	feet.y = clampf(feet.y, area.y * 0.45, area.y - PANEL_HEIGHT - 20.0)
	_enemy_home = Vector2(feet.x - _enemy.size.x / 2.0, feet.y - _enemy.size.y * 0.85)
	_enemy.position = _enemy_home
	_shadow.size = Vector2(_enemy.size.x * 0.9, 46)
	_shadow.position = feet - _shadow.size / 2.0
	_enemy_box.position = Vector2(20, 20)
	_player_box.position = Vector2(20, area.y - PANEL_HEIGHT - 134.0)

func _sharp(rect: TextureRect) -> void:
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

func _info_box() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Ui.frame())
	panel.custom_minimum_size.x = 286
	var column := VBoxContainer.new()
	panel.add_child(column)
	_stage.add_child(panel)
	return panel

func _add_label(parent: Node, label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)

func _button(parent: Node, text: String, action: Callable) -> void:
	var button := Ui.button("%d. %s" % [_buttons.size() + 1, text])
	button.pressed.connect(action)
	parent.add_child(button)
	_buttons.append(button)
