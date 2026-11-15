extends CharacterBody3D

@export var speed: float = 20.0
@export var turn_speed: float = 1.5      # How sharply arrow keys curve the ball
@export var homing_strength: float = 2.0 # How strongly the ball pulls back toward the target
@export var target: Node3D

func _ready() -> void:
	if target:
		look_at(target.global_position)

func _physics_process(delta: float) -> void:
	# Smoothly steer back toward the target every frame
	if target:
		var target_transform = global_transform.looking_at(target.global_position, global_transform.basis.y)
		global_transform.basis = global_transform.basis.slerp(target_transform.basis, homing_strength * delta)

	# Add curve on top with arrow keys
	var turn_x = Input.get_axis("ui_right", "ui_left")
	var turn_y = Input.get_axis("ui_down", "ui_up")
	
	rotate_object_local(Vector3.UP, turn_x * turn_speed * delta)
	rotate_object_local(Vector3.RIGHT, turn_y * turn_speed * delta)
	
	# Move forward and check for collisions
	var forward = -global_transform.basis.z
	var collision = move_and_collide(forward * speed * delta)
	
	# Bounce off whatever it hits
	if collision:
		var bounce_dir = forward.bounce(collision.get_normal())
		look_at(global_position + bounce_dir, global_transform.basis.y)


func _on_hitbox_body_entered(body: Node3D) -> void:
	get_tree().change_scene_to_file("res://death.tscn")


func _on_area_3d_body_entered(body: Node3D) -> void:
	get_tree().change_scene_to_file("res://death.tscn")
