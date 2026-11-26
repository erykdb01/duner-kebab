extends StaticBody3D
# Kosz: niszczy trzymany przedmiot z grupy "trashable".

const Sfx = preload("res://Scripts/sfx.gd")

func get_prompt(player) -> String:
	if not player.held:
		return "Kosz"
	return "[E] Wyrzuć" if player.held.is_in_group("trashable") else "Tego nie wyrzucisz"

func interact(player) -> void:
	if player.held and player.held.is_in_group("trashable"):
		player.discard()
		Sfx.play_at(self, "trash")
