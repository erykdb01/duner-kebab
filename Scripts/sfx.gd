extends RefCounted
# Jednorazowe dźwięki z folderu Sounds. Odtwarzacz sam znika po zagraniu.

# Dźwięk bez położenia (interfejs, gracz). "parent" musi działać, gdy ma być słychać.
static func play(parent: Node, sound: String, volume_db := 0.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = load("res://Sounds/%s.wav" % sound)
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	parent.add_child(player)
	player.play()

# Dźwięk w miejscu "at" - słychać, z której strony dochodzi.
static func play_at(at: Node3D, sound: String, volume_db := 0.0) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = load("res://Sounds/%s.wav" % sound)
	player.volume_db = volume_db
	player.unit_size = 4.0
	player.finished.connect(player.queue_free)
	# Rodzicem jest scena, bo "at" może zaraz zniknąć.
	var parent := at.get_tree().current_scene
	parent.add_child(player)
	player.global_position = at.global_position
	player.play()

# Pętla (tło, radio): po zagraniu startuje od nowa.
static func make_loop(player, sound: String) -> void: # dowolny AudioStreamPlayer
	player.stream = load("res://Sounds/%s.wav" % sound)
	player.finished.connect(player.play)
