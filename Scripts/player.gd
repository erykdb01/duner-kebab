extends CharacterBody3D

signal prompt_changed(text: String)

@onready var cam = $Camera3D
@onready var col = $CollisionShape3D
@onready var ray: RayCast3D = $Camera3D/InteractRay
@onready var hand = $Camera3D/Hand

var held: Area3D = null
var _held_layer := 0
var _prompt := ""

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ray.add_exception(self)

func _unhandled_input(e):
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if e is InputEventMouseButton and e.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif e.is_action_pressed("interact"):
		_interact()
	elif e is InputEventMouseMotion:
		rotate_y(-e.relative.x * 0.003)
		cam.rotation.x = clamp(cam.rotation.x - e.relative.y * 0.003, -1.5, 1.5)

func _physics_process(delta):
	var crouch = Input.is_action_pressed("crouch")
	var h = 1.2 if crouch else 1.75
	col.shape.height = h
	col.position.y = h / 2
	cam.position.y = h - 0.15

	if not is_on_floor():
		velocity += get_gravity() * delta

	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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
	if target:
		text = target.get_prompt(self)
	elif _can_place():
		text = "[E] Wypuść szczura" if held.is_in_group("rat") else "[E] Odłóż"
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)
