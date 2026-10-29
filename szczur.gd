extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	randomize()
	_ruch()

func _ruch() -> void:
	var random_pos := Vector3(
		randf_range(-5.0, 5.0),
		global_position.y,
		randf_range(-5.0, 5.0)
	)
	agent.target_position = random_pos

func _physics_process(delta: float) -> void:
	if agent.is_navigation_finished():
		_ruch()
		return

	var destination = agent.get_next_path_position()
	var direction = destination - global_position
	direction.y = 0.0
	direction = direction.normalized()

	velocity = direction * 1.0
	move_and_slide()
