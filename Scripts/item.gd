extends Area3D
# Przedmiot, który gracz może wziąć do ręki. Początek sceny = spód przedmiotu.

@export var item_name := "Przedmiot"

func get_prompt(player) -> String:
	return "" if player.held else "[E] Weź: " + item_name

func interact(player) -> void:
	if not player.held:
		player.hold(self)
