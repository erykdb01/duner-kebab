extends Control
# Menu główne: lokal nocą w tle, biegające szczury i przyciski.

const Game = preload("res://Scripts/game.gd")
const Sfx = preload("res://Scripts/sfx.gd")
const Night = preload("res://Scripts/night.gd")
const GAME_SCENE := "res://Scenes/game.tscn"
const RAT_SIZE := Vector2(144, 78)
const FRAME_TIME := 0.12

var _time := 0.0
var _rats: Array[Dictionary] = []

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Night.dark = false
	%Play.pressed.connect(_new_game)
	%Continue.pressed.connect(get_tree().change_scene_to_file.bind(GAME_SCENE))
	%Controls.pressed.connect(func(): %Help.visible = not %Help.visible)
	%Quit.pressed.connect(get_tree().quit)
	# Postęp pamiętany tylko do wyłączenia gry.
	%Continue.visible = not Game.save.is_empty()
	if %Continue.visible:
		%Continue.text = "Kontynuuj (noc %d)" % Game.save["night"]
		%Continue.grab_focus()
	else:
		%Play.grab_focus()
	Sfx.make_loop($radio, "radio")
	$radio.play()
	_add_rat("szczur", -200.0, 130.0)
	_add_rat("pimpek", -700.0, 95.0)
	_add_rat("szczur", 1900.0, -160.0)

func _process(delta: float) -> void:
	_time += delta
	# Kamera lekko się kołysze, tytuł mruga jak stary neon.
	%Camera.look_at(Vector3(1.8 + sin(_time * 0.25) * 0.35, 2.0 + sin(_time * 0.4) * 0.08, -5.0))
	var flicker := fmod(_time, 6.0) < 0.3 and fmod(_time, 0.1) < 0.05
	%Title.modulate.a = 0.55 if flicker else 1.0
	for rat in _rats:
		var node: TextureRect = rat["node"]
		var speed: float = rat["speed"]
		node.position.x += speed * delta
		node.position.y = size.y - RAT_SIZE.y - 6.0
		# Po wybiegnięciu za ekran wraca z drugiej strony.
		if speed > 0.0 and node.position.x > size.x + 250.0:
			node.position.x = -400.0
		elif speed < 0.0 and node.position.x < -450.0:
			node.position.x = size.x + 600.0
		var frames: Array = rat["frames"]
		node.texture = frames[int(_time / FRAME_TIME) % 2]

func _add_rat(variant: String, x: float, speed: float) -> void:
	var node := TextureRect.new()
	var frames := [
		load("res://Textures/szczury/%s_0.png" % variant),
		load("res://Textures/szczury/%s_1.png" % variant)]
	node.texture = frames[0]
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.size = RAT_SIZE
	node.position.x = x
	node.flip_h = speed < 0.0
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%Rats.add_child(node)
	_rats.append({"node": node, "speed": speed, "frames": frames})

func _new_game() -> void:
	Game.new_game()
	get_tree().change_scene_to_file(GAME_SCENE)
