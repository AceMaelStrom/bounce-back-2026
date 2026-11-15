extends Node3D

@onready var animation_player: AnimationPlayer = $"../../../AnimationPlayer"
@onready var power_bar: ProgressBar = $"../../../PowerUI/PowerBar"
@onready var ball: Ball = get_tree().get_first_node_in_group("ball")
@export var swordready = false

var power := 0.0

func _process(delta: float) -> void:
	if Input.is_action_pressed("swing"):
		animation_player.play("sword_load")
		power += 35.0 * delta
		if power > 100:
			power = 100

	if Input.is_action_just_released("swing"):
		animation_player.play("sword_swing")
		ball.hit_power = power
		power = 0

	power_bar.value = power

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body is Ball:
		$zweihander/parrysound.play(0.15)
