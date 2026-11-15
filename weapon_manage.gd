extends Node3D

@onready var animation_player: AnimationPlayer = $"../../../AnimationPlayer"
@onready var power_bar: ProgressBar = $"../../../PowerUI/PowerBar"
@onready var ball: Ball = get_tree().get_first_node_in_group("ball")
@onready var hitbox: Area3D = $zweihander/hitbox

var power := 0.0
var saved_power := 0.0
var hit_time := 0.0

func _ready() -> void:
	hitbox.monitoring = false

func _process(delta: float) -> void:
	if hit_time > 0:
		hit_time -= delta
		if hit_time <= 0:
			hitbox.monitoring = false

	if Input.is_action_just_pressed("swing"):
		animation_player.play("sword_load")

	if Input.is_action_pressed("swing"):
		power += 35.0 * delta
		if power > 100:
			power = 100

	if Input.is_action_just_released("swing"):
		animation_player.play("sword_swing")
		saved_power = power
		hit_time = 1.0
		power = 0
		hitbox.monitoring = true

	power_bar.value = power
	#1

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body is Ball and hit_time > 0:
		body.hit_power = saved_power
		body._on_hitbox_body_entered(body)
		$zweihander/parrysound.play(0.15)
		hit_time = 0
		hitbox.set_deferred("monitoring", false)
