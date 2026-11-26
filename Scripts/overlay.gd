extends CanvasLayer
# Pauza (Esc) i podsumowanie nocy. Działa także przy zatrzymanej grze.

const MENU_SCENE := "res://Scenes/menu.tscn"

var _summary := false

@onready var title: Label = %Title
@onready var details: Label = %Details
@onready var resume_button: Button = %Resume

func _ready() -> void:
	hide()
	resume_button.pressed.connect(_resume)
	%Restart.pressed.connect(_restart)
	%Menu.pressed.connect(_to_menu)
	%Quit.pressed.connect(get_tree().quit)

func _unhandled_input(event: InputEvent) -> void:
	if _summary or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if visible:
		_resume()
	else:
		_open("Pauza", "")

func show_summary(text: String) -> void:
	_summary = true
	_open("Koniec nocy", text)
	resume_button.hide()

func _open(heading: String, text: String) -> void:
	title.text = heading
	details.text = text
	details.visible = not text.is_empty()
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _resume() -> void:
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
