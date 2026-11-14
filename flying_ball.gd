extends CharacterBody3D

@export var speed: float = 20.0
@export var turn_speed: float = 1.5
@export var target: Node3D # Drag or assign your target object here in the Inspector

func _ready() -> void:
	# Point the ball directly at the target when the game starts
	if target:
		look_at(target.global_position)

func _physics_process(delta: float) -> void:
	# 1. Curve left/right and up/down using arrow keys
	var turn_x = Input.get_axis("ui_right", "ui_left")
	var turn_y = Input.get_axis("ui_down", "ui_up")
	
	rotate_object_local(Vector3.UP, turn_x * turn_speed * delta)
	rotate_object_local(Vector3.RIGHT, turn_y * turn_speed * delta)
	
	# 2. Fly forward in whichever direction it is currently facing
	var forward = -global_transform.basis.z
	var collision = move_and_collide(forward * speed * delta)
	
	# 3. Bounce off walls
	if collision:
		var bounce_dir = forward.bounce(collision.get_normal())
		look_at(global_position + bounce_dir, global_transform.basis.y)
