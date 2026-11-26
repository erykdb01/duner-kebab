extends CanvasLayer

@onready var prompt = $Prompt
@onready var money = $Money
@onready var order = $Order
@onready var payment = $Payment

var _payment_tween: Tween

func show_prompt(text: String) -> void:
	prompt.text = text

func show_money(amount: int) -> void:
	money.text = "Kasa: %d zł" % amount

func show_orders(lines: Array[String]) -> void:
	order.text = "Zamówienia:\n" + "\n".join(lines) if lines else ""

# "+X zł" pod kasą, znika po chwili.
func show_payment(amount: int) -> void:
	payment.text = "+%d zł" % amount
	payment.modulate.a = 1.0
	if _payment_tween:
		_payment_tween.kill()
	_payment_tween = create_tween()
	_payment_tween.tween_property(payment, "modulate:a", 0.0, 0.6).set_delay(1.8)
