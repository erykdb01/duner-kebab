extends Area3D
# Radio w kuchni: kilka stacji (pokrętło obok) i nocne wiadomości.

const Sfx = preload("res://Scripts/sfx.gd")
const NEWS_TIME := 7.0
const KNOB_STEP := TAU / 8.0
# [nazwa stacji, plik z folderu Sounds]
const STATIONS: Array = [
	["Radio Kebab 66,6 FM", "radio"],
	["Disco Maszynka 92,1 FM", "radio_disco"],
	["Nocny Spokój 101,3 FM", "radio_noc"],
	["Radio Remiza 88,8 FM", "radio_polka"],
]
const NEWS: Array[String] = [
	"Sanepid rekrutuje. Wymagane\nwłasne sztuczne wąsy.",
	"Ceny wołowiny w górę.\nEksperci: są alternatywy.",
	"Właścicielka szczura:\n\"Pimpek reaguje na imię\".",
	"Pogoda: noc. Potem dalej noc.",
	"Smakosz roku: \"Liczy się\nświeżość\".",
	"Pozdrowienia dla kucharza.\nWiemy, co robisz.",
]

var _on := false
var _station := 0
var _news := 0
var _time := 0.0

@onready var music: AudioStreamPlayer3D = $music
@onready var label: Label3D = $Label
@onready var dial: Node3D = $knob/dial

func _ready() -> void:
	Sfx.make_loop(music, STATIONS[_station][1])

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
	Sfx.play_at(self, "switch")
	if _on:
		_on = false
		music.stop()
		label.text = ""
	else:
		_play()

# Wywoływane przez pokrętło; wyłączone radio od razu gra następną stację.
func next_station() -> void:
	_station = (_station + 1) % STATIONS.size()
	music.stream = load("res://Sounds/%s.wav" % STATIONS[_station][1])
	create_tween().tween_property(dial, "rotation:x", KNOB_STEP, 0.15).as_relative()
	Sfx.play_at(self, "switch")
	_play()

func station_name() -> String:
	return STATIONS[_station][0]

# Najpierw na chwilę nazwa stacji, potem wiadomości.
func _play() -> void:
	_on = true
	_time = NEWS_TIME / 2.0
	label.text = station_name()
	music.play()
