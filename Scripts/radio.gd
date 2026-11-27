extends Area3D
# Radio w kuchni: muzyka i nocne wiadomości.

const Sfx = preload("res://Scripts/sfx.gd")
const NEWS_TIME := 7.0
const NEWS: Array[String] = [
	"Radio Kebab 66,6 FM",
	"Sanepid rekrutuje. Wymagane\nwłasne sztuczne wąsy.",
	"Ceny wołowiny w górę.\nEksperci: są alternatywy.",
	"Właścicielka szczura:\n\"Pimpek reaguje na imię\".",
	"Pogoda: noc. Potem dalej noc.",
	"Smakosz roku: \"Liczy się\nświeżość\".",
	"Pozdrowienia dla kucharza.\nWiemy, co robisz.",
]

var _on := false
var _news := 0
var _time := 0.0

@onready var music: AudioStreamPlayer3D = $music
@onready var label: Label3D = $Label

func _ready() -> void:
	Sfx.make_loop(music, "radio")

func _process(delta: float) -> void:
	if not _on:
		return
	_time -= delta
	if _time <= 0.0:
		_time = NEWS_TIME
		label.text = NEWS[_news]
		_news = (_news + 1) % NEWS.size()

func get_prompt(_player) -> String:
	return "[E] Wyłącz radio" if _on else "[E] Włącz radio"

func interact(_player) -> void:
	_on = not _on
	_time = 0.0
	Sfx.play_at(self, "switch")
	if _on:
		music.play()
	else:
		music.stop()
		label.text = ""
