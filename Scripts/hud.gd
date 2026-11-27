extends CanvasLayer

@onready var prompt = $Prompt
@onready var money = $Money
@onready var payment = $Payment

const Ui = preload("res://Scripts/pixel_ui.gd")

var _payment_tween: Tween
var _message_tween: Tween
var _work := PanelContainer.new() # pasek postępu pod celownikiem
var _work_title: Label
var _work_bar := ProgressBar.new()

func _ready() -> void:
	_work.theme = Ui.theme()
	_work.add_theme_stylebox_override("panel", Ui.frame())
	_work.set_anchors_preset(Control.PRESET_CENTER)
	_work.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_work.offset_top = 42.0
	_work.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_work.add_child(column)
	_work_title = Ui.label(18)
	_work_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_work_title)
	_work_bar.max_value = 1.0
	_work_bar.step = 0.01
	Ui.bar(column, _work_bar)
	var fill: StyleBoxFlat = _work_bar.get_theme_stylebox("fill")
	fill.bg_color = Ui.ACCENT
	add_child(_work)
	_work.hide()

# Pusta nazwa chowa pasek; "progress" 0..1.
func show_work(title: String, progress: float) -> void:
	_work.visible = not title.is_empty()
	_work_title.text = title
	_work_bar.value = progress

func show_prompt(text: String) -> void:
	prompt.text = text

func show_money(amount: int, rent: int) -> void:
	money.text = "Kasa: %d zł / czynsz: %d zł" % [amount, rent]

# Ważna wiadomość na górze ekranu, znika po "time" sekundach.
func show_message(text: String, time: float) -> void:
	$Message.text = text
	$Message.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_property($Message, "modulate:a", 0.0, 0.8).set_delay(time)

func show_clock(text: String) -> void:
	$Clock.text = text

# Truchła w torbie i worek z żywym szczurem (pod zegarem).
func show_inventory(text: String) -> void:
	$Inventory.text = text

func show_warning(text: String) -> void:
	$Warning.text = text

# "+X zł" (albo mandat na czerwono) pod kasą, znika po chwili.
func show_payment(amount: int) -> void:
	payment.text = "%+d zł" % amount
	payment.modulate = Color.WHITE if amount >= 0 else Color(1.6, 0.35, 0.35)
	if _payment_tween:
		_payment_tween.kill()
	_payment_tween = create_tween()
	_payment_tween.tween_property(payment, "modulate:a", 0.0, 0.6).set_delay(1.8)
