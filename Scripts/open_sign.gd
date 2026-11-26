extends Area3D
# Tabliczka przy drzwiach: obrócenie na "OTWARTE" zaczyna noc.

signal opened

var is_open := false

@onready var label: Label3D = $Label

func get_prompt(_player) -> String:
	return "Otwarte do świtu" if is_open else "[E] Otwórz lokal"

func interact(_player) -> void:
	if is_open:
		return
	is_open = true
	label.text = "OTWARTE"
	label.modulate = Color(0.45, 1, 0.5)
	opened.emit()
