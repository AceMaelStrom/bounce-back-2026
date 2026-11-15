class_name Ball
extends CharacterBody3D

@export var speed: float = 20.0
@export var turn_speed: float = 0.35
@export var homing_strength: float = 4.0
@export var close_homing_strength: float = 10.0
@export var target: Node3D
@export var speedTarget: Node3D
@export var bounceTarget: Node3D

@export	var homing_call := 0

@onready var ball_cam: Camera3D = $BallCam
@onready var momentum_ui: CanvasLayer = $MomentumUI
@onready var momentum_bar: ProgressBar = $MomentumUI/MomentumBar
@onready var player_cam: Camera3D = target.get_node("neck/eyes")
@onready var power_ui: CanvasLayer = target.get_node("PowerUI")

var homing_on := true
var falling := false
var fall_speed := 0.0
var hit_power := 0.0
var momentum := 0.0
var target_offset := Vector3.ZERO
var changing_scene := false

func _ready() -> void:
	if target:
		look_at(target.global_position)

	ball_cam.position = Vector3(0, 2, 6)
	ball_cam.look_at(global_position)
	momentum_ui.visible = false

func _physics_process(delta: float) -> void:
	if ball_cam.current and homing_on == false and falling == false:
		var turn_x = Input.get_axis("ui_right", "ui_left")
		var turn_y = Input.get_axis("ui_down", "ui_up")
		rotate_object_local(Vector3.UP, turn_x * turn_speed * delta)
		rotate_object_local(Vector3.RIGHT, turn_y * turn_speed * delta)

		momentum -= 10.0 * delta
		if momentum < 0:
			momentum = 0
		momentum_bar.value = momentum

		if momentum == 0:
			falling = true

	if target and homing_on:
		var target_position = target.global_position + target_offset
		var current_homing = homing_strength
		var distance_to_target = global_position.distance_to(target_position)

		if distance_to_target < 10.0:
			current_homing = close_homing_strength

		var target_transform = global_transform.looking_at(target_position, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_transform.basis, current_homing * delta)

		if ball_cam.current and global_position.distance_to(target.global_position) < 30.0:
			player_cam.make_current()
			momentum_ui.visible = false
			power_ui.visible = true

	var forward = -global_transform.basis.z
	var movement = forward * speed * delta

	if falling:
		fall_speed += 20.0 * delta
		movement.y -= fall_speed * delta

	var collision = move_and_collide(movement)

	if collision:
		var collider = collision.get_collider()

		if collider is Player and homing_on:
			go_to_scene("res://death.tscn")
			return

		if homing_on == false and collider.get_collision_layer_value(1):
			if collider.is_in_group("glass") and momentum >= 40:
				collider.visible = false
				collider.queue_free()
				momentum += 40.0
				momentum_bar.value = momentum
				
			pause_homing(1.5)
			falling = false
			fall_speed = 0
			target_offset.x = randf_range(-5.0, 5.0)
			target_offset.y = randf_range(1.0, 4.5)
			target_offset.z = randf_range(-3.0, 3.0)

		var bounce_dir = movement.normalized().bounce(collision.get_normal())
		look_at(global_position + bounce_dir, global_transform.basis.y)

func pause_homing(seconds: float) -> void:
	homing_on = false
	homing_call += 1
	var homingfirst := homing_call
	await get_tree().create_timer(seconds).timeout
	if homingfirst == homing_call:
		homing_on = true

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body == self:
		homing_on = false
		falling = false
		fall_speed = 0
		momentum = 30.0 + hit_power * 0.7
		speed = momentum + hit_power / 5.0
		momentum_bar.value = momentum
		target_offset = Vector3.ZERO
		rotate_object_local(Vector3.UP, PI)
		ball_cam.make_current()
		momentum_ui.visible = true
		power_ui.visible = false

func go_to_scene(scene_path: String) -> void:
	if changing_scene:
		return

	changing_scene = true
	get_tree().call_deferred("change_scene_to_file", scene_path)


func _on_target_hitbox_body_entered(body: Node3D) -> void:
	if body != self:
		return

	homing_call += 1
	homing_on = false
	falling = false
	fall_speed = 0

	speed += 5
	if speed > 40:
		speed = 40

	momentum += 20
	if momentum > 100:
		momentum = 100

	momentum_bar.value = momentum

	var current_direction = -global_transform.basis.z
	var next_target = bounceTarget.get_node("bounceHitbox").global_position
	var target_direction = (next_target - global_position).normalized()
	var new_direction = current_direction.lerp(target_direction, 0.15).normalized()

	look_at(global_position + new_direction, Vector3.UP)
