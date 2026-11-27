extends Area3D
# Tabliczka przy drzwiach: obrócenie na "OTWARTE" otwiera lokal.

signal opened

const Sfx = preload("res://Scripts/sfx.gd")

var is_open := false

@onready var label: Label3D = $Label

func get_prompt(_player) -> String:
	return "Otwarte do świtu" if is_open else "[E] Otwórz lokal"

func interact(_player) -> void:
	open()

# Gracz obraca tabliczkę albo gra robi to sama, gdy minie czas przygotowań.
func open() -> void:
	if is_open:
		return
	is_open = true
	label.text = "OTWARTE"
	label.modulate = Color(0.45, 1, 0.5)
	Sfx.play_at(self, "switch")
	opened.emit()
