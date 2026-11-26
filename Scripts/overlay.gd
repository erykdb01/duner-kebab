extends CanvasLayer
# Pauza (Esc) i podsumowanie nocy. Działa także przy zatrzymanej grze.

const Game = preload("res://Scripts/game.gd")
const MENU_SCENE := "res://Scenes/menu.tscn"

var _summary := false
var _next_action := Callable()
var _new_game_on_restart := false

@onready var title: Label = %Title
@onready var details: Label = %Details
@onready var resume_button: Button = %Resume

func _ready() -> void:
	hide()
	resume_button.pressed.connect(_resume)
	%Next.pressed.connect(func(): _next_action.call())
	%Next.hide()
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

# Podsumowanie nocy; przycisk "next_label" prowadzi dalej.
func show_summary(heading: String, text: String, next_label: String, next_action: Callable) -> void:
	_summary = true
	_next_action = next_action
	_open(heading, text)
	resume_button.hide()
	%Next.text = next_label
	%Next.show()
	%Next.grab_focus()

# Koniec gry: można tylko zacząć od nowa albo wyjść.
func show_finale(heading: String, text: String) -> void:
	_summary = true
	_open(heading, text)
	resume_button.hide()
	%Next.hide()
	%Restart.text = "Zagraj od nowa"
	_new_game_on_restart = true

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
	if _new_game_on_restart:
		Game.new_game()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
