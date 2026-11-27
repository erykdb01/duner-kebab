extends CanvasLayer

@onready var prompt = $Prompt
@onready var money = $Money
@onready var payment = $Payment

var _payment_tween: Tween
var _message_tween: Tween

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
