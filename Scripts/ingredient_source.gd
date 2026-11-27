extends Area3D
# Pojemnik lub butelka: dodaje jeden składnik na deskę.

@export var ingredient: StringName
@export var board_path: NodePath
@export var stock := -1 # liczba porcji; -1 = bez limitu

@onready var board = get_node(board_path)

func _ready() -> void:
	_refresh()

func get_prompt(player) -> String:
	if stock == 0:
		return "Brak mięsa - zmiel szczury"
	var prompt: String = board.add_prompt(ingredient, player)
	return prompt if stock < 0 else "%s (porcje: %d)" % [prompt, stock]

func interact(player) -> void:
	if stock != 0 and board.add(ingredient, player) and stock > 0:
		stock -= 1
		_refresh()

func refill(portions: int) -> void:
	stock += portions
	_refresh()

# Stan z poprzedniej nocy.
func set_stock(portions: int) -> void:
	stock = portions
	_refresh()

# Kupka składnika (węzeł "heap") znika, gdy nic nie zostało.
func _refresh() -> void:
	if stock >= 0:
		$heap.visible = stock > 0
		$fill.visible = stock > 0
