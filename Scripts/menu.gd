extends Control
# Menu główne.

const GAME_SCENE := "res://Scenes/game.tscn"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%Play.pressed.connect(get_tree().change_scene_to_file.bind(GAME_SCENE))
	%Quit.pressed.connect(get_tree().quit)
	%Play.grab_focus()
