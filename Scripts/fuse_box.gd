extends Area3D
# Skrzynka z bezpiecznikami na podwórku. Po awarii trzeba przynieść z kuchni nowy bezpiecznik.

signal restored

const Sfx = preload("res://Scripts/sfx.gd")
const ON_COLOR := Color(0.2, 1, 0.3)
const OFF_COLOR := Color(1, 0.15, 0.1)

var tripped := false

@onready var lever: Node3D = $lever
@onready var lamp: OmniLight3D = $lamp

func _ready() -> void:
	_refresh()

func trip() -> void:
	tripped = true
	_refresh()

func get_prompt(player) -> String:
	if not tripped:
		return "Bezpieczniki: wszystko gra"
	if _has_fuse(player):
		return "[E] Włóż nowy bezpiecznik"
	return "Spalony bezpiecznik!\nZapasowe leżą w kuchni."

func interact(player) -> void:
	if not tripped or not _has_fuse(player):
		return
	player.discard()
	tripped = false
	_refresh()
	Sfx.play_at(self, "switch")
	restored.emit()

func _has_fuse(player) -> bool:
	return player.held != null and player.held.is_in_group("fuse")

# Brak dźwigni = spalony bezpiecznik.
func _refresh() -> void:
	lever.visible = not tripped
	lamp.light_color = OFF_COLOR if tripped else ON_COLOR
	lamp.light_energy = 1.8 if tripped else 0.5
