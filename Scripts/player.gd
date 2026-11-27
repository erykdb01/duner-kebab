extends CharacterBody3D

signal prompt_changed(text: String)
signal sack_used # [R]: wyjęcie szczura z worka albo schowanie
signal eat_pressed # [G]: zjedzenie trzymanego kebaba

const Sfx = preload("res://Scripts/sfx.gd")

var torch := SpotLight3D.new()

@onready var cam = $Camera3D
@onready var col = $CollisionShape3D
@onready var ray: RayCast3D = $Camera3D/InteractRay
@onready var hand = $Camera3D/Hand

var held: Area3D = null
var _held_layer := 0
var _prompt := ""
var busy := false # rozmowa, notatnik, wołanie, walka, minigra albo praca przy desce: gracz stoi
var work_title := "" # nazwa trwającej pracy; niepusta = nie można nawet się rozejrzeć
var _work_left := 0.0
var _work_total := 1.0
var _work_done := Callable()
var carcasses := 0 # truchła szczurów w torbie (z kanałów)
var big_carcasses := 0 # truchła wielkich szczurów (więcej mięsa)
var sack := &"" # żywy szczur w worku ("szczur" albo "pimpek"); pusty = wolny worek

# Praca (nakładanie, zawijanie, jedzenie): bez ruchu, rozglądania i jakichkolwiek akcji
# (mysz zostaje schwytana, działa tylko pauza). Pasek postępu rysuje HUD.
func start_work(title: String, time: float, done := Callable()) -> void:
	busy = true
	work_title = title
	_work_left = time
	_work_total = time
	_work_done = done

# 0..1
func work_progress() -> float:
	return clampf(1.0 - _work_left / _work_total, 0.0, 1.0)

func _process(delta: float) -> void:
	if work_title.is_empty():
		return
	_work_left -= delta
	if _work_left > 0.0:
		return
	busy = false
	work_title = ""
	if _work_done.is_valid():
		_work_done.call()

func add_carcasses(count: int) -> void:
	carcasses = maxi(carcasses + count, 0)

func add_big_carcasses(count: int) -> void:
	big_carcasses = maxi(big_carcasses + count, 0)

func set_sack(variant: StringName) -> void:
	sack = variant

func set_busy(value: bool) -> void:
	busy = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED

# Płynnie obraca widok na podany punkt (twarz rozmówcy).
func look_toward(point: Vector3) -> void:
	var offset: Vector3 = point - cam.global_position
	var yaw := atan2(-offset.x, -offset.z)
	var pitch := atan2(offset.y, Vector2(offset.x, offset.z).length())
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "rotation:y", rotation.y + wrapf(yaw - rotation.y, -PI, PI), 0.35)
	tween.tween_property(cam, "rotation:x", clampf(pitch, -1.5, 1.5), 0.35)

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ray.add_exception(self)
	torch.light_color = Color(1, 0.94, 0.8)
	torch.light_energy = 2.2
	torch.spot_range = 10.0
	torch.spot_angle = 32.0
	torch.position = Vector3(0.2, -0.15, 0)
	torch.visible = false
	cam.add_child(torch)

func _unhandled_input(e):
	if busy:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if e is InputEventMouseButton and e.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif e.is_action_pressed("interact"):
		_interact()
	elif e.is_action_pressed("sack"):
		sack_used.emit()
	elif e.is_action_pressed("eat"):
		eat_pressed.emit()
	elif e.is_action_pressed("flashlight"):
		torch.visible = not torch.visible
		Sfx.play(self, "switch", -8.0)
	elif e is InputEventMouseMotion:
		rotate_y(-e.relative.x * 0.003)
		cam.rotation.x = clamp(cam.rotation.x - e.relative.y * 0.003, -1.5, 1.5)

func _physics_process(delta):
	var crouch = not busy and Input.is_action_pressed("crouch")
	var h = 1.2 if crouch else 1.75
	if work_title.is_empty(): # przy pracy widok stoi w miejscu, także w kucki
		col.shape.height = h
		col.position.y = h / 2
		cam.position.y = h - 0.15

	if not is_on_floor():
		velocity += get_gravity() * delta

	var input = Vector2.ZERO if busy else Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back")
	var dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var speed = 1.5 if crouch else 5.0
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

	_update_prompt()

# --- Interakcje ---

func hold(item: Area3D) -> void:
	held = item
	_held_layer = item.collision_layer
	item.collision_layer = 0
	item.reparent(hand, false)
	item.transform = Transform3D.IDENTITY

func discard() -> void:
	if held.has_method("consume"):
		held.consume()
	held.queue_free()
	held = null

func _place(point: Vector3) -> void:
	var item = held
	held = null
	item.reparent(get_parent(), false)
	item.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), point)
	item.collision_layer = _held_layer
	if item.has_method("release"):
		item.release(point)

# Obiekt pod celownikiem, który ma metody interact() i get_prompt().
func _target() -> Object:
	var hit = ray.get_collider()
	return hit if hit and hit.has_method("interact") else null

# Przedmiot można odłożyć tylko na w miarę poziomej powierzchni.
func _can_place() -> bool:
	return held != null and ray.is_colliding() and ray.get_collision_normal().y > 0.7

func _interact() -> void:
	ray.force_raycast_update()
	var target = _target()
	if target:
		target.interact(self)
	elif _can_place():
		_place(ray.get_collision_point())

func _update_prompt() -> void:
	var target = _target()
	var text := ""
	if busy:
		pass
	elif target:
		text = target.get_prompt(self)
	elif _can_place():
		text = "[E] Wypuść szczura" if held.is_in_group("rat") else "[E] Odłóż"
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)
