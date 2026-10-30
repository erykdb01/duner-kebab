extends CharacterBody3D

@onready var cam = $Camera3D
@onready var col = $CollisionShape3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(e):
	if e is InputEventMouseMotion:
		rotate_y(-e.relative.x * 0.003)
		cam.rotation.x = clamp(cam.rotation.x - e.relative.y * 0.003, -1.5, 1.5)

func _physics_process(delta):
	var crouch = Input.is_key_pressed(KEY_CTRL)
	var h = 1.2 if crouch else 1.6
	col.shape.height = h
	col.position.y = h / 2
	cam.position.y = h - 0.3

	if is_on_floor():
		if Input.is_key_pressed(KEY_SPACE):
			velocity.y = 2.5
	else:
		velocity.y -= 9.8 * delta

	var x = int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
	var z = int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	var dir = (transform.basis * Vector3(x, 0, z)).normalized()
	var speed = 0.5 if crouch else 2.0
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()
