class_name Ball
extends CharacterBody3D

@export var speed: float = 20.0
@export var turn_speed: float = 1.5
@export var homing_strength: float = 2.0
@export var close_homing_strength: float = 10.0
@export var target: Node3D

var changing_scene := false

func _ready() -> void:
	if target:
		look_at(target.global_position)

func _physics_process(delta: float) -> void:
	# Curve the ball with the arrow keys
	var turn_x = Input.get_axis("ui_right", "ui_left")
	var turn_y = Input.get_axis("ui_down", "ui_up")
	
	rotate_object_local(Vector3.UP, turn_x * turn_speed * delta)
	rotate_object_local(Vector3.RIGHT, turn_y * turn_speed * delta)

	# Turn back toward the player
	if target:
		var current_homing = homing_strength
		var distance_to_player = global_position.distance_to(target.global_position)

		# Turn faster when close so the ball does not circle the player
		if distance_to_player < 10.0:
			current_homing = close_homing_strength

		var target_transform = global_transform.looking_at(target.global_position, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_transform.basis, current_homing * delta)
	
	# Move the ball
	var forward = -global_transform.basis.z
	var collision = move_and_collide(forward * speed * delta)
	
	# Check what the ball hit
	if collision:
		if collision.get_collider() is Player:
			go_to_scene("res://death.tscn")
			return

		# Bounce off walls and the floor
		var bounce_dir = forward.bounce(collision.get_normal())
		look_at(global_position + bounce_dir, global_transform.basis.y)


func _on_hitbox_body_entered(body: Node3D) -> void:
	go_to_scene("res://hit.tscn")


func _on_area_3d_body_entered(body: Node3D) -> void:
	# Only change scenes if this ball entered the player's area
	if body == self:
		go_to_scene("res://death.tscn")


func go_to_scene(scene_path: String) -> void:
	if changing_scene:
		return

	changing_scene = true
	get_tree().call_deferred("change_scene_to_file", scene_path)
