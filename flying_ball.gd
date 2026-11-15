class_name Ball
extends CharacterBody3D

@export var speed: float = 20.0
@export var return_speed: float = 16.0
@export var turn_speed: float = 0.35
@export var curve_return_speed: float = 0.8
@export var homing_strength: float = 4.0
@export var close_homing_strength: float = 10.0
@export var target: Node3D
@export var speedTarget: Node3D
@export var bounceTarget: Node3D

@onready var ball_cam: Camera3D = $BallCam
@onready var momentum_ui: CanvasLayer = $MomentumUI
@onready var momentum_bar: ProgressBar = $MomentumUI/MomentumBar
@onready var player_cam: Camera3D = target.get_node("neck/eyes")
@onready var power_ui: CanvasLayer = target.get_node("PowerUI")
@onready var ball_material = $ballmesh3.get_active_material(0).duplicate() as StandardMaterial3D

var launched := false
var homing_on := true
var falling := false
var fall_speed := 0.0
var hit_power := 0.0
var momentum := 0.0
var target_offset := Vector3.ZERO
var move_direction := Vector3(0, 0, -1)
var course_direction := Vector3(0, 0, -1)
var return_delay := 0.0
var steer_pause := 0.0
var bounce_cooldown := 0.0
var target_bounce_cooldown := 0.0
var path_points: Array[Vector3] = []
var path_number := 0
var retracing := false
var launch_safe_time := 0.0
var changing_scene := false

func _ready() -> void:
	move_direction = (target.global_position - global_position).normalized()
	course_direction = move_direction
	look_at(global_position + move_direction)

	ball_cam.position = Vector3(0, 2, 6)
	ball_cam.look_at(global_position)
	momentum_ui.visible = false

	$ballmesh3.set_surface_override_material(0, ball_material)
	ball_material.emission_enabled = true
	ball_material.emission_energy_multiplier = 2.5

func _physics_process(delta: float) -> void:
	if launch_safe_time > 0:
		launch_safe_time -= delta

	if steer_pause > 0:
		steer_pause -= delta

	if bounce_cooldown > 0:
		bounce_cooldown -= delta

	if target_bounce_cooldown > 0:
		target_bounce_cooldown -= delta

	if return_delay > 0:
		return_delay -= delta
		if return_delay <= 0:
			homing_on = true

	if launched and not homing_on and not retracing:
		path_points.append(global_position)

	if launched and not homing_on and not falling and not retracing and return_delay <= 0:
		var turn_x = Input.get_axis("ui_right", "ui_left")
		var turn_y = Input.get_axis("ui_down", "ui_up")

		move_direction = move_direction.rotated(Vector3.UP, turn_x * turn_speed * momentum/10 * delta)
		var right_direction = move_direction.cross(Vector3.UP).normalized()
		if right_direction == Vector3.ZERO:
			right_direction = Vector3.RIGHT
		move_direction = move_direction.rotated(right_direction, turn_y * turn_speed * momentum/10 * delta)
		move_direction = move_direction.slerp(course_direction, curve_return_speed * delta).normalized()

		momentum -= 10.0 * delta
		if momentum <= 0:
			momentum = 0
			falling = true

		speed = 12.0 + momentum * 0.23
		momentum_bar.value = momentum

		var blue_amount = momentum / 100.0
		blue_amount = blue_amount * blue_amount
		var blue_value = clampi(roundi(blue_amount * 255.0), 0, 255)
		var ball_color = Color8(0, 0, blue_value)
		ball_material.albedo_color = ball_color
		ball_material.emission = ball_color
		ball_material.emission_energy_multiplier = 0.5 + blue_amount * 2.0

	if retracing:
		speed = return_speed

		if path_number >= 0 and path_number < path_points.size():
			var path_position = path_points[path_number]
			var path_distance = global_position.distance_to(path_position)

			if path_distance < 0.4:
				path_number -= 1
				if path_number >= 0:
					path_position = path_points[path_number]

			if path_number >= 0:
				move_direction = (path_position - global_position).normalized()

			if path_number < path_points.size() / 2 and ball_cam.current:
				player_cam.make_current()
				momentum_ui.visible = false
				power_ui.visible = true
		else:
			retracing = false
			homing_on = true
			target_offset = Vector3.ZERO

	if target and homing_on:
		speed = return_speed
		var target_position = target.global_position + target_offset
		var player_distance = global_position.distance_to(target.global_position)

		if player_distance < 14:
			target_position = target.global_position + Vector3(0, 1, 0)

		var target_direction = (target_position - global_position).normalized()
		var current_homing = homing_strength

		if player_distance < 14:
			current_homing = close_homing_strength

		if steer_pause <= 0:
			if player_distance < 8:
				move_direction = target_direction
			else:
				var turn_amount = minf(current_homing * delta, 1.0)
				move_direction = move_direction.slerp(target_direction, turn_amount).normalized()

		if global_position.distance_to(target.global_position + Vector3(0, 1, 0)) < 0.8:
			go_to_scene("res://death.tscn")
			return

		if ball_cam.current and global_position.distance_to(target.global_position) < 30:
			player_cam.make_current()
			momentum_ui.visible = false
			power_ui.visible = true

	var move_velocity = move_direction * speed

	if falling:
		fall_speed += 20.0 * delta
		move_velocity.y -= fall_speed

	var collision = move_and_collide(move_velocity * delta)

	if collision:
		var collider = collision.get_collider()
		var normal = collision.get_normal()

		# Bounce target reflect off the real surface normal
		# Checked first so wall logic can't start a retrace
		if bounceTarget and collider is Node3D:
			if collider == bounceTarget or bounceTarget.is_ancestor_of(collider) or collider.is_in_group("bounce_target"):
				_bounce_off_target(normal)
				global_position += normal * 0.15   # push out so it doesn't re-hit
				return

		if collider is Player:
			if homing_on or retracing:
				go_to_scene("res://death.tscn")
				return
			elif launch_safe_time > 0:
				global_position += move_direction * 1.0
				return

		if collider.is_in_group("glass") and not homing_on and momentum >= 40:
			collider.visible = false
			collider.call_deferred("queue_free")
			momentum += 15
			if momentum > 100:
				momentum = 100
			momentum_bar.value = momentum
			global_position += move_direction * 1.1
			$glassbreak.play()
			return

		if collider.get_collision_layer_value(1) and retracing:
			global_position += move_direction * 0.2

		elif collider.get_collision_layer_value(1) and bounce_cooldown <= 0:
			bounce_cooldown = 0.12

			if not homing_on:
				retracing = true
				falling = false
				fall_speed = 0
				momentum = 0
				momentum_bar.value = 0
				ball_material.albedo_color = Color.BLACK
				ball_material.emission = Color.BLACK
				target_offset = Vector3.ZERO
				path_number = path_points.size() - 2

				if path_number >= 0:
					move_direction = (path_points[path_number] - global_position).normalized()
					course_direction = move_direction
					global_position += move_direction * 0.2
			else:
				retracing = false
				homing_on = true

		elif bounce_cooldown >= 0.11:
			var hit_direction = move_velocity.normalized()
			move_direction = hit_direction.bounce(normal).normalized()
			course_direction = move_direction
			global_position += normal * 0.12

	if move_direction != Vector3.ZERO:
		var up_direction = Vector3.UP
		if absf(move_direction.dot(Vector3.UP)) > 0.98:
			up_direction = Vector3.FORWARD
		look_at(global_position + move_direction, up_direction)

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body != self:
		return

	launched = true
	homing_on = false
	falling = false
	fall_speed = 0
	return_delay = 0
	retracing = false
	launch_safe_time = 0.4
	target_bounce_cooldown = 0.0
	path_points.clear()
	path_number = 0
	momentum = 30.0 + hit_power * 0.7
	if momentum > 100:
		momentum = 100
	speed = 12.0 + momentum * 0.23
	momentum_bar.value = momentum
	target_offset = Vector3.ZERO
	move_direction = -player_cam.global_transform.basis.z.normalized()
	course_direction = move_direction
	look_at(global_position + move_direction)
	ball_cam.make_current()
	momentum_ui.visible = true
	power_ui.visible = false

func _on_target_hitbox_body_entered(body: Node3D) -> void:
	if body != self or homing_on:
		return

	falling = false
	fall_speed = 0
	return_delay = 0
	momentum = minf(momentum + 15.0, 100.0)
	momentum_bar.value = momentum

	var next_target = bounceTarget.get_node("bounceHitbox").global_position
	var target_direction = (next_target - global_position).normalized()
	move_direction = move_direction.slerp(target_direction, 0.2).normalized()
	course_direction = move_direction

# Area3D version: no real surface normal, so use the hitbox's own Y axis.
# If it reflects the wrong way, try basis.z instead of basis.y.
func _on_bounce_hitbox_body_entered(body: Node3D) -> void:
	if body != self or homing_on or target_bounce_cooldown > 0.0 or not bounceTarget:
		return

	var hitbox: Node3D = bounceTarget.get_node("bounceHitbox")
	_bounce_off_target(hitbox.global_transform.basis.y.normalized())

func _bounce_off_target(normal: Vector3) -> void:
	if target_bounce_cooldown > 0.0:
		return
	target_bounce_cooldown = 0.12

	# Reflect off the surface bounce() works on normal
	move_direction = move_direction.bounce(normal).normalized()

	# A homing ball just ricochets and keeps homing steering takes over again
	if homing_on:
		return

	launched = true
	retracing = false
	falling = false
	fall_speed = 0.0
	return_delay = 0.0

	momentum = minf(momentum + 5.0, 100.0)
	momentum_bar.value = momentum

	course_direction = move_direction

func go_to_scene(scene_path: String) -> void:
	if changing_scene:
		return

	changing_scene = true
	get_tree().call_deferred("change_scene_to_file", scene_path)
