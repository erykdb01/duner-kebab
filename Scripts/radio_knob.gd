extends Area3D
# Pokrętło radia: zmienia stację.

@onready var radio = get_parent()

func get_prompt(_player) -> String:
	return "[E] Zmień stację\n(teraz: %s)" % radio.station_name()

func interact(_player) -> void:
	radio.next_station()
